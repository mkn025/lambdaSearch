
{-# LANGUAGE ScopedTypeVariables #-}

module TraversalFunctions (
      DirContent
    , FileInfomation(..)
    , treverseDirWithSettings
    , constructFilePath
    , executeOnFile
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

import System.Posix.FilePath                        ((</>))
import Foreign.Ptr as PTR                           (Ptr, nullPtr)
import System.Process                               (createProcess, proc, waitForProcess)
import System.Exit                                  (ExitCode (..))

import System.Posix.Directory.Internals             (DirStream(DirStream), CDir, CDirent)

import UnliftIO.Exception                           (bracketOnError)
import Control.Exception.Base                       (catch)
import System.IO.Error                              (isPermissionError)

import TraversalSettings (
      Arguments     (..)
    , SearchSetting (..)
    , getDisallowFilter
    , getHiddenFilter
    , getExtentionFilter
    , compileRegexFilter
    , getRexPattern
    , executeFunction
    , ConstrucedCommand
    , substituePath
    , convertToString
    , convertString

    )
import Control.Monad.Except (
      runExceptT
    , ExceptT(..)
    )


type DirContent = (DirType, RawFilePath)

data FileInfomation = FileInfomation{
      filePath      :: RawFilePath
    , fileNameInfo  :: Maybe DirContent -- Nothing dersom det er en mappe
} deriving (Eq,Show)


-- hehe viktig at vi burker safe call for alt som gjør IO
--  https://github.com/haskell/unix/issues/34

foreign import ccall safe "readdir"
  c_readdir :: Ptr CDir -> IO (Ptr CDirent) --Leser fra allerede åpenet dirStream -- Byttet fra readDir-R

foreign import ccall unsafe "__hscore_d_name"
  c_name :: Ptr CDirent -> IO CString

foreign import ccall unsafe "__posixdir_d_type"
  c_type :: Ptr CDirent -> IO DirType




-- | En funksjon som pattern matcher og henter ut pekeren
unpackDirStream :: DirStream -> Ptr CDir
unpackDirStream (DirStream a) = a

data DirError = UnexpectedErrnoZero | ReadDirErr Errno

instance Show DirError where
    show (ReadDirErr (Errno n)) = "ReadDirErr: Ernno code: " <> show n
    show UnexpectedErrnoZero    = "UnexpectedErrnoZero"

instance Exception DirError



-- | Leser neste element fra en åpen 'DirStream' med @readdir@.
--
-- - Leser fra en allerede åpnet dirstream.
-- - Returnerer @Nothing@ ved slutten av katalogen.
-- - Kaster feil når systemkallet faktisk feiler.
type DirContentT = ExceptT DirError IO (Maybe DirContent)

readDirEnt :: DirStream ->  DirContentT
readDirEnt dir = ExceptT readContent
    where
    readContent :: IO (Either DirError (Maybe DirContent))
    readContent = do
      let dirp = unpackDirStream dir
    -- fra docs : set errno to zero before calling readdir()
      resetErrno 

      dEnt <- c_readdir dirp
      if dEnt == PTR.nullPtr
        then do
          err <- getErrno
          case err of
            e | e == eINTR  -> readContent                        -- Retry on interrupt
              | e == eOK    -> pure . Right $ Nothing             -- End of directory
              | e == eACCES -> pure . Right $ Nothing             -- Om du ikke har til tilgang til filen
              | e == ePERM  -> pure . Right $ Nothing             -- Om du ikke har lov å gjøre oppprasjonen. 
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
            Nothing   -> pure s0         -- access denied, skipper
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
                                                  acc' <- run $ f acc content
                                                  loop run acc' dirp


-- | Traverserer katalogtreet rekursivt og putter det og har en fold funksjon bestemmer hvordan den skal legge inn helemeter
--
-- Se rapport for mer informasjon
-- Sjekker om @rootPath@ er en dir, så bruker @foldFunc@ på hvert element
-- (unntatt @.@ og @..@). Er elementet en en dir treveserer den rekusrsivt
--
-- * Er @rootPath@ ikke en direrctory da er  @acc@ uendret.
foldDirectoryTree
    :: forall a . (a -> RawFilePath -> DirContent -> IO a)  --  forall scoopes a in hele func function
    -> a -- 
    -> RawFilePath
    -> IO a
foldDirectoryTree foldFunc acc rootPath  = do
    isDir <- isDirectory <$> getFileStatus  rootPath
    if not isDir
        then pure acc
        else traverseDirectoryContents innerloop acc rootPath
    where
        innerloop  :: a -> DirContent -> IO a
        innerloop currentAcc dc@(typ,filename) = do
            let filePath = rootPath  </> filename
            let isDir = typ == dtDir
            -- legge funskjonen på 
            nextAcc <- foldFunc currentAcc rootPath dc
            if not isDir
                then pure nextAcc
                else foldDirectoryTree foldFunc nextAcc filePath


-- | Rekkursiv traversering med aktive filter
--  Går igjennom alle filene og rekusrsivt. Og akkumlerer ønskete filer i acc listen vår
treversRecursively :: Arguments -> [FileInfomation] -> RawFilePath -> IO [FileInfomation]
treversRecursively args = foldDirectoryTree foldFunc
    where
    regexCompiled = compileRegexFilter args
    foldFunc :: [FileInfomation] -> RawFilePath -> DirContent -> IO [FileInfomation]
    foldFunc acc parentPath dc@(typ,file)  = do

        let fullPath = parentPath  </> file
        let isDir = typ == dtDir

        if isDir
            -- Sjekker om det er en hidden folder
            then if getHiddenFilter args file 
                 then pure $ FileInfomation {filePath = fullPath, fileNameInfo = Nothing} : acc
                 else pure acc 
            else do
                let rg  = getRexPattern      regexCompiled file
                let hf  = getHiddenFilter    args file
                let ef  = getExtentionFilter args file
                let df  = getDisallowFilter  args parentPath
                if and [rg, ef, hf, df]
                then do
                    executeFunction args fullPath executeOnFile
                    pure $ FileInfomation {filePath = parentPath, fileNameInfo = Just dc} : acc
                else do
                    pure acc


-- | Kjører en kommando på på en filen vår 
--  Vente på om den. Gir tom tupel om good. Eller gir ioError  ellers
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
--  Treverser med mange i cwd dersom du ikke gir noe dir
treveseManyPathsWithArgs  :: Arguments ->  Maybe [FilePath]  -> IO [FileInfomation]
treveseManyPathsWithArgs ff Nothing   = getWorkingDirectory  >>= treverseOnPathWithArgs ff . convertToString
treveseManyPathsWithArgs ff (Just fp) = concat <$> mapM (treverseOnPathWithArgs ff) fp

-- | Treveser en filsti
--  difinere hvordan vi skal jobbe på en filepath. Slik at vi etterpå kan mapM på en liste med filepath
treverseOnPathWithArgs :: Arguments -> FilePath -> IO [FileInfomation]
treverseOnPathWithArgs ff sp = treversRecursively ff [] $ convertString sp

-- Hjelpemeothde som lager helefilstien dersom, dersom det er en sti
constructFilePath :: FileInfomation -> Maybe String
constructFilePath fi = case fileNameInfo fi of
                        Nothing               -> Nothing
                        Just (_ ,b)           -> Just $ convertToString $ filePath fi </>  b

