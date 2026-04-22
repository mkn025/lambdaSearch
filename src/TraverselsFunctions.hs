

-- | TODO: Dokumenter traversering av kataloger og filtrering av filer.
module TraverselsFunctions (
      DirContent
    , FileInfomation(..)
    , treverseDirWithSettings
    , constructFilePath 
    )
where


import System.Posix.Directory.Foreign               (DirType(..), dtDir )
import System.Posix.ByteString.FilePath             (RawFilePath, peekFilePath )
import Foreign.C.Error                              (Errno  (..), eINTR,  getErrno, resetErrno,eOK, eACCES, ePERM )
import Foreign.C.String                             (CString )
import UnliftIO                                     (MonadUnliftIO, finally,askRunInIO, throwIO, Exception )
import System.Posix.Files.ByteString                (isDirectory, getFileStatus)
import Control.Monad.IO.Class                       (MonadIO(liftIO) )

import System.Posix.Directory.ByteString as PosixBS (openDirStream, closeDirStream, DirStream, getWorkingDirectory)

import qualified Data.ByteString.Char8   as BS      (unpack, pack)
import System.Posix.FilePath                        ((</>))
import Foreign.Ptr as PTR                           (Ptr, nullPtr)
import System.Process                               (createProcess, proc, waitForProcess)
import System.Exit                                  (ExitCode (..))

import System.Posix.Directory.Internals             (DirStream(DirStream), CDir, CDirent)

import UnliftIO.Exception                           (bracketOnError)
import Control.Exception.Base                       (catch)
import System.IO.Error                              (isPermissionError)

import TraversalSettings (
      Arguments   (..)
    , SearchSetting (..)
    , getDisallowFilter
    , getHiddenFilter
    , getExtentionFilter
    , compileRegexFilter
    , getRexPattern
    , executeFunction
    , ConstrucedCommand
    , substituePath
    )

import Control.Monad.Except (
      runExceptT
    , ExceptT(..)
    )


type DirContent = (DirType, RawFilePath)


-- | TODO: Dokumenter informasjonen som lagres per fil eller mappe.
data FileInfomation = FileInfomation{
      filePath         :: RawFilePath
    , dirContent       :: Maybe DirContent -- Nothing dersom det er en mappe som i
} deriving (Eq,Show)



foreign import ccall unsafe "readdir"
  c_readdir_new :: Ptr CDir -> IO (Ptr CDirent) --Leser fra allerede åpenet dirStream

foreign import ccall unsafe "__hscore_d_name"
  c_name :: Ptr CDirent -> IO CString

foreign import ccall unsafe "__posixdir_d_type"
  c_type :: Ptr CDirent -> IO DirType



-- | TODO: Dokumenter hvordan en 'DirStream' pakkes ut til en C-peker.
unpackDirStream :: DirStream -> Ptr CDir
unpackDirStream (DirStream a) = a

-- | TODO: Dokumenter feiltyper ved lesing av kataloginnhold.
data DirError = UnexpectedErrnoZero | ReadDirErr Errno

instance Show DirError where
    show (ReadDirErr (Errno n)) = "ReadDirErr: Ernno code: " <> show n
    show UnexpectedErrnoZero    = "UnexpectedErrnoZero"

instance Exception DirError
type DirContentT = ExceptT DirError IO (Maybe DirContent)


-- | Leser neste element fra en åpen 'DirStream' med @readdir@.
--
-- TODO: Dokumenter detaljene rundt pekerhåndtering, EOF, og feilbehandling.
-- Eksisterende notat (språkvasket):
--
-- - Leser fra en allerede åpen strøm.
-- - Returnerer @Nothing@ ved slutten av katalogen.
-- - Kaster bare feil når systemkallet faktisk feiler.
readDirEnt :: DirStream ->  DirContentT
readDirEnt dir = ExceptT readContent
    where
    readContent :: IO (Either DirError (Maybe DirContent))
    readContent = do
      let dirp = unpackDirStream dir
      resetErrno

      -- c_readdir_new :: Ptr CDir -> IO (Ptr CDirent)
      dEnt <- c_readdir_new dirp
      if dEnt == PTR.nullPtr
        then do
          err <- getErrno
          case err of
            e | e == eINTR  -> readContent                        -- Retry on interrupt
            e | e == eOK    -> pure . Right $ Nothing             -- End of directory
            e | e == eACCES -> pure . Right $ Nothing             -- Om du ikke har til tilgang til filen
            e | e == ePERM  -> pure . Right $ Nothing             -- Om du ikke har lov å gjøre oppprasjonen
              | otherwise   -> pure . Left  $ ReadDirErr err      -- Real error

              -- har mulihet å legge til flere type feil 
        else do
          dName <- c_name dEnt >>= peekFilePath
          dType <- c_type dEnt

        -- fra wiki. Vi trenger ikke å free den
        -- IMPORTANT: do NOT free dEnt for readdir()

        -- On success, readdir() returns a pointer to a dirent structure.
        -- (This structure may be statically allocated; do not attempt to
        -- free(3) it.)
          pure . Right . Just  $ (dType, dName)



-- | Traverserer innholdet i en katalog med en fold-funksjon.
-- | bruker funksjonen
--
-- Åpner en dirSteam til @p@, bruker @f@ på hvert element altås hver feil
-- (unntatt @.@ og @..@), og returnerer den akkumulerte verdien.
--
-- * Tillatelseskfeil  håndteres ved at den skipper den
-- * Andre IO-feil kastes videre.
-- * Katalogstrømmen lukkes alltid, også ved expetions ('bracketOnError' + 'finally').
traverseDirectoryContents :: (MonadUnliftIO m)
                          => (a -> DirContent -> m a)
                          -> a
                          -> RawFilePath
                          -> m a
traverseDirectoryContents f s0 p = do

    run <- askRunInIO
    liftIO $ bracketOnError
        (openDirStreamPermissive p)
        (mapM_ PosixBS.closeDirStream)   -- kjøre bare dersom den kaster feil. 
        (\case
            Nothing   -> pure s0         -- access denied, skip silently
            Just dirp -> loop run s0 dirp `finally` PosixBS.closeDirStream dirp)

  where
    openDirStreamPermissive :: RawFilePath -> IO (Maybe DirStream)
    openDirStreamPermissive path =
        (Just <$> PosixBS.openDirStream path)
        `catch`
        \errMsg -> if isPermissionError errMsg 
                   then pure Nothing 
                   else throwIO errMsg

    loop run acc dirp = do
        dirAnd <- runExceptT $ readDirEnt dirp
        case dirAnd of
            Left  errMsg                   -> throwIO errMsg
            Right Nothing                  -> pure acc          -- Om den er kommeet til enden av dir
            Right (Just content@(_typ, e)) -> if e == "." || e == ".."
                                              then loop run acc dirp
                                              else do
                                                  acc' <- run (f acc content)
                                                  loop run acc' dirp


-- | Traverserer katalogtreet rekursivt og putter det og har en fold funksjon bestemmer hvordan den skal legge inn helemeter
--
-- Sjekker om @rootPath@ er en dir, så bruker @foldFunc@ på hvert element
-- (unntatt @.@ og @..@). Er elementet en en dir treveserer den rekusrsivt
--
-- * Er @rootPath@ ikkje ein katalog, returneras @acc@ uendra.
foldDirectoryTree
    :: (a -> RawFilePath -> DirContent -> IO a) -- Foldfunction
    -> a -- 
    -> RawFilePath
    -> IO a
foldDirectoryTree foldFunc acc rootPath  = do

    isDir <- isDirectory <$> getFileStatus  rootPath
    if not isDir
        then pure acc
        else traverseDirectoryContents innerloop acc rootPath
    where
        innerloop currentAcc dc@(typ,filename) = do

            let filePath = rootPath  </> filename
            let isDir = typ == dtDir

            -- legge funskjonen på  
            nextAcc <- foldFunc currentAcc rootPath dc
            if not isDir
                then pure nextAcc
                else foldDirectoryTree foldFunc nextAcc filePath



-- | rekkursiv traversering med aktive filtere og eventuell kommando-kjøring. 
-- TODO: skriv mer
treversRecursively_ :: Arguments -> [FileInfomation] -> RawFilePath -> IO [FileInfomation]
treversRecursively_ args = foldDirectoryTree foldFunc 
    where
    regexCompiled = compileRegexFilter args
    foldFunc :: [FileInfomation] -> RawFilePath -> DirContent -> IO [FileInfomation]
    foldFunc acc parentPath dc@(typ,file)  = do

        let fullPath = parentPath  </> file
        let isDir = typ == dtDir
        if isDir
            then pure $ FileInfomation {filePath = fullPath, dirContent = Nothing}:acc -- om den er nothign så er det bare en mappe
            else do
                let rg = getRexPattern      regexCompiled file
                let hf = getHiddenFilter    args file
                let df = getDisallowFilter  args parentPath
                let ef = getExtentionFilter args file
                if and [rg, df, ef, hf]
                then do
                    executeFunction args fullPath executeOnFile
                    pure $ FileInfomation {filePath = parentPath, dirContent = Just dc} : acc
                -- Om et av filter blir False, da går den her og legg ikke i noe
                else pure acc



-- | kjøree 
-- TODO: skriv mer
executeOnFile :: ConstrucedCommand -> RawFilePath ->  IO ()
executeOnFile c@(prog, args) rfd = do
                                let argsWithPath = substituePath args rfd
                                (_, _, _, ph) <- createProcess $ proc prog argsWithPath
                                ec <- waitForProcess ph
                                case ec of
                                    ExitSuccess   -> pure ()
                                    ExitFailure n -> ioError $ userError (
                                           "Command failed: "
                                        <> show c
                                        <> " (exit " ++ show n ++ ")"    )





-- | Treveser med søkinstillinger
treverseDirWithSettings  :: SearchSetting -> IO [FileInfomation]
treverseDirWithSettings ss = treveseManyPathsWithArgs  (arguments ss) (searchPaths ss)


-- | Treverser med argumter, standardsti velges når ingen søkestier er oppgitt.
-- | Treverser med mange stier
treveseManyPathsWithArgs  :: Arguments ->  Maybe [FilePath]  -> IO [FileInfomation]
treveseManyPathsWithArgs ff Nothing   = getWorkingDirectory  >>= treverseOnPathWithArgs ff . BS.unpack
treveseManyPathsWithArgs ff (Just fp) = concat <$> mapM (treverseOnPathWithArgs ff) fp

-- | Treveser en filsti
treverseOnPathWithArgs :: Arguments -> FilePath -> IO [FileInfomation]
treverseOnPathWithArgs ff sp = treversRecursively_ ff [] $ BS.pack sp


-- Hjelpemeothde som lager helefilstien dersom, dersom det er en sti
constructFilePath :: FileInfomation -> Maybe String
constructFilePath fi = case dirContent fi of
                        Nothing     -> Nothing
                        Just (_ ,b) ->  Just $ BS.unpack $ filePath fi </>  b
