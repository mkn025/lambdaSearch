module TraverselsFunctions (
      DirContent
    , FileInfomation(..)
    , treverseDirWithSettings
    , constructFilePath 
    )


import System.Posix.Directory.Foreign               (DirType(..), dtDir )
import System.Posix.ByteString.FilePath             (RawFilePath, peekFilePath )
import Foreign.C.Error                              (Errno  (..), eINTR,  getErrno, resetErrno,eOK )
import Foreign.C.String                             (CString )
import UnliftIO                                     (MonadUnliftIO, finally,askRunInIO, throwIO, Exception )
import System.Posix.Files.ByteString                (isDirectory, getFileStatus)
import Control.Monad.IO.Class                       (MonadIO(liftIO) )

import System.Posix.Directory.ByteString as PosixBS (openDirStream, closeDirStream, DirStream, getWorkingDirectory )
import qualified Data.ByteString.Char8   as BS      (unpack, pack)
import System.Posix.FilePath                        ((</>))
import Foreign.Ptr as PTR                           (Ptr, nullPtr)
import System.Process                               (createProcess, proc, waitForProcess)
import System.Exit                                  (ExitCode (..))

import System.Posix.Directory.Internals             (DirStream(DirStream), CDir, CDirent)

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

data FileInfomation = FileInfomation{
      filePath         :: RawFilePath
    , dirContent       :: Maybe DirContent -- Nothing dersom det er en mappe som ikke har
    } deriving (Eq,Show)

foreign import ccall unsafe "readdir"
  c_readdir_new :: Ptr CDir -> IO (Ptr CDirent) --Leser fra allerede åpenet dirStream

foreign import ccall unsafe "__hscore_d_name"
  c_name :: Ptr CDirent -> IO CString

foreign import ccall unsafe "__posixdir_d_type"
  c_type :: Ptr CDirent -> IO DirType


unpackDirStream :: DirStream -> Ptr CDir
unpackDirStream (DirStream a) = a

data DirError = UnexpectedErrnoZero | ReadDirErr Errno

instance Show DirError where
    show (ReadDirErr (Errno n)) = "ReadDirErr: Ernno code: " <> show n
    show UnexpectedErrnoZero    = "UnexpectedErrnoZero"

instance Exception DirError
type DirContentT = ExceptT DirError IO (Maybe DirContent)


-- | Funksjonen leser en Enten en Dirstram ved å bruke readDir syscall. Eller så gir den  en feil
-- | Fungere ved å allocere minne til pekeren. så så leser vi hva som er på pekeren
-- | Men skriver også det blir lest til etr_dEnt. Derfor vi kan hente ut fra pekeren
-- | bruker transformatoren siden vi øsnker bare å kaste å gi feil dersom syscallet feiler. ikke når den vi er på slutten
-- | vil derfor ha mulighet til å 
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
            e | e == eINTR -> readContent                        -- Retry on interrupt
            e | e == eOK   -> pure . Right $ Nothing             -- End of directory
              | otherwise  -> pure . Left  $ ReadDirErr err      -- Real error
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


traverseDirectoryContents :: (MonadUnliftIO m)
                          => (a -> DirContent -> m a)   -- Fold funksjon
                          -> a                          -- Accumulator [Tenkt at det skal være en lite]
                          -> RawFilePath                -- Directory path
                          -> m a
traverseDirectoryContents f s0 p = do
    dirp      <- liftIO $ PosixBS.openDirStream p
    liftToIO_ <- askRunInIO  --askRunInIO :: MonadUnliftIO m => m (m a -> IO a) -- jukser det litt til, men takk hoogle
    liftIO (loop liftToIO_ s0 dirp) `finally` liftIO (PosixBS.closeDirStream dirp)
  where
    loop run acc dirp = do
        dirAnd <- runExceptT $ readDirEnt dirp
        case dirAnd of
            Left errMsg                    -> throwIO errMsg -- kaster IO siden da er vi sikker på at den kjører closeDirStream 
            Right Nothing                  -> pure acc       -- stoper dersom dir ikke klarer å lese. 
            Right (Just content@(_typ, e)) -> if e == "." || e == ".."
                                              then loop run acc dirp
                                              else do
                                                acc' <- run $ f acc content
                                                loop run acc' dirp



-- | En funksjone som definerer generetlt hvordan den skal treverse igjennom  filsystemet 
-- | Den har også en fold funkson som bestemmer hvordan den skal sammele opp listne  
foldDirectoryTree
    :: (a -> RawFilePath -> DirContent -> IO a) -- Foldfunction
    -> a
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



executeOnFile :: ConstrucedCommand -> RawFilePath ->  IO ()
executeOnFile c@(prog, args) rfd = do
                                let argsWithPath = substituePath args rfd
                                print argsWithPath
                                (_, _, _, ph) <- createProcess $ proc prog argsWithPath
                                ec <- waitForProcess ph
                                case ec of
                                    ExitSuccess   -> pure ()
                                    ExitFailure n -> ioError $ userError (
                                           "Command failed: "
                                        <> show c
                                        <> " (exit " ++ show n ++ ")"    )




treverseDirWithSettings  :: SearchSetting -> IO [FileInfomation]
treverseDirWithSettings ss = treveseManyPathsWithArgs  (arguments ss) (searchPaths ss)

treveseManyPathsWithArgs  :: Arguments ->  Maybe [FilePath]  -> IO [FileInfomation]
treveseManyPathsWithArgs ff Nothing   = getWorkingDirectory  >>= treverseOnPathWithArgs ff . BS.unpack
treveseManyPathsWithArgs ff (Just fp) = concat <$> mapM (treverseOnPathWithArgs ff) fp

treverseOnPathWithArgs :: Arguments -> FilePath -> IO [FileInfomation]
treverseOnPathWithArgs ff sp = treversRecursively_ ff [] $ BS.pack sp


constructFilePath :: FileInfomation -> Maybe String
constructFilePath fi = case dirContent fi of
                        Nothing     -> Nothing
                        Just (_ ,b) ->  Just $ BS.unpack $ filePath fi </>  b

