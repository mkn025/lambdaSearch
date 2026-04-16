{- HLINT ignore "Use let" -}
{- HLINT ignore "Avoid lambda" -}
{- HLINT ignore "Use if" -}


module TraverselsFunctions (
     treverPathWithFilterArgs
    , DirContent
    , treverseDirWithSettings
    , executeOnFile 
    )
where

import System.Posix.Directory.Foreign ( DirType(..), dtDir )

import System.Posix.ByteString.FilePath ( RawFilePath, peekFilePath )
import Foreign.C.Error                  ( Errno(..), eINTR,  getErrno, resetErrno,eOK )
import Foreign.C.String                 ( CString )
import Foreign.C.Types                  ( CInt (..), CInt )

import UnliftIO                      (MonadUnliftIO, finally,askRunInIO, throwIO, Exception )
import System.Posix.Files.ByteString (isDirectory, getFileStatus)
import Control.Monad.IO.Class        ( MonadIO(liftIO) )

import System.Posix.Directory.ByteString as PosixBS (openDirStream, closeDirStream, DirStream, getWorkingDirectory )
import qualified Data.ByteString.Char8 as BS        (unpack, pack)
import System.Posix.FilePath                        ((</>))
import Foreign.Ptr as PTR                           (Ptr, nullPtr)
import System.Process                               (createProcess, proc, waitForProcess,readCreateProcessWithExitCode)
import System.Exit                                  (ExitCode (..))
import System.IO                                    (stderr ,hPutStrLn )




import System.Posix.Directory.Internals             (DirStream(DirStream) , CDir , CDirent )

import TraversalSettings (
      Arguments   (..)
    , SearchSetting (..)
    , getDisallowFilter
    , getHiddenFilter
    , getExtentionFilter
    , compileRegexFilter
    , getRexPattern
    , Command
    , executeFunction
    )

import Control.Monad.Except (
      runExceptT
    , ExceptT(..)
    )
import UnliftIO.Internals.Async (Conc(Pure))


type DirContent = (DirType,RawFilePath)

foreign import ccall safe "__hscore_readdir"
  c_readdir  :: Ptr CDir -> Ptr (Ptr CDirent) -> IO CInt  --der c skriver adressen. eller pekeren til adressen til neste dir entry

 -- readdir_r var  depreciated  ... rip  vil derfor ikke fungere derfor ikke distroer
 -- It is recommended that applications use readdir(3) instead of
 -- readdir_r().  Furthermore, since glibc 2.24, glibc deprecates
 -- readdir_r().  The reasons are as follows:
 -- https://www.man7.org/linux/man-pages/man3/readdir_r.3.html 



foreign import ccall unsafe "__hscore_free_dirent"
  c_freeDirEnt  :: Ptr CDirent -> IO ()

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
          dName <- c_name dEnt >>= (\l -> peekFilePath l)
          dType <- c_type dEnt

        -- fra wiki. Vi trenger ikke å free den
        -- IMPORTANT: do NOT free dEnt for readdir()

        -- On success, readdir() returns a pointer to a dirent structure.
        -- (This structure may be statically allocated; do not attempt to
        -- free(3) it.)
          pure . Right . Just  $ (dType, dName)

traverseDirectoryContents :: (MonadUnliftIO m)
                          => (a -> DirContent -> m a)   -- fold funksjon
                          -> a                          -- accumulator [Tenkt at det skal være en lite]
                          -> RawFilePath                -- directory path
                          -> m a
traverseDirectoryContents f s0 p = do
    dirp      <- liftIO $ PosixBS.openDirStream p
    liftToIO_ <- askRunInIO  -- askRunInIO :: MonadUnliftIO m => m (m a -> IO a) -- jukser det litt til, men takk hoogle
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



treversRecursively :: Arguments -> [DirContent] -> RawFilePath -> IO [DirContent]
treversRecursively flt arr rfp =  topLoop
    where
    regexCompiled = seq const $ compileRegexFilter flt
    topLoop :: IO [DirContent]
    topLoop = do
        isDir <- liftIO $ isDirectory <$> getFileStatus rfp
        if not isDir
            then pure arr
            else traverseDirectoryContents innerLoop arr rfp
        where
            innerLoop :: [DirContent] -> DirContent -> IO [DirContent]
            innerLoop acc t@(typ,file) = do
                let fullpath = rfp </> file  --legg sammen slik at vi er inne på riktig sti
                isDir <- pure $ typ == dtDir
                if not isDir

                    then do
                        rg  <- pure $ getRexPattern      regexCompiled file
                        df  <- pure $ getDisallowFilter  flt rfp
                        hf  <- pure $ getHiddenFilter    flt file
                        ef  <- pure $ getExtentionFilter flt file
                        
                        if and [rg, df, ef, hf]
                            then do
                                executeFunction flt fullpath executeOnFile
                                pure  $ (typ, fullpath) : acc
                            else pure acc
                    else treversRecursively flt (t : acc) fullpath


-- Sånn sett dårlig, men det holder forløpig det


executeOnFile :: Command -> RawFilePath ->  IO ()
executeOnFile cmd rfd = case generateCmdAndArgs cmd rfd of
                            Nothing -> pure ()
                            Just (prog,args)  -> do
                                (_, _, _, ph) <- createProcess (proc prog args) 
                                ec <- waitForProcess ph
                                case ec of
                                    ExitSuccess   -> pure ()
                                    ExitFailure n -> ioError (userError ("Command failed: " ++ show cmd ++ " (exit " ++ show n ++ ")"))








  -- print child output

generateCmdAndArgs :: Command -> RawFilePath -> Maybe (String, [String])
generateCmdAndArgs [] _        = Nothing
generateCmdAndArgs (x:xs) path = Just (x, map (substituteForPath path) xs )
            where
                  substituteForPath :: RawFilePath -> String ->  String
                  substituteForPath rfp s = if s == "{}" then BS.unpack rfp else s




treverseDirWithSettings  :: SearchSetting -> IO [DirContent]
treverseDirWithSettings ss = treveseManyPathsWithArgs  (arguments ss) (searchPaths ss)

treveseManyPathsWithArgs  :: Arguments ->  Maybe [FilePath]  -> IO [DirContent]
treveseManyPathsWithArgs ff Nothing   = getWorkingDirectory  >>= treverPathWithFilterArgs ff . BS.unpack
treveseManyPathsWithArgs ff (Just fp) = concat <$> mapM (treverPathWithFilterArgs ff) fp

treverPathWithFilterArgs :: Arguments -> FilePath -> IO [DirContent]
treverPathWithFilterArgs ff sp = treversRecursively ff [] $ BS.pack sp


