module FileSystem.Raw (foldDirectoryTree) where

-- Alt FFI og i skal ligger her
import Core.TraversalTypes (
      DirType        (..)
    , AbsolutPath    (..)
    , FilePaths      (..)
    , DirContent     (..)
    
    )


-- Filter And helpers --


import System.Posix.Directory.ByteString as PosixBS (DirStream,closeDirStream, openDirStream)

import System.Posix.ByteString.FilePath  (RawFilePath, peekFilePath)
import Foreign.C.Error                   (Errno               (..), eINTR,  getErrno, resetErrno,eOK, eACCES, ePERM )
import Foreign.C.String                  (CString)
import UnliftIO                          (MonadUnliftIO, finally,askRunInIO, throwIO, Exception )
import Control.Monad.IO.Class            (MonadIO             (liftIO) )

import Foreign.Ptr as PTR                (Ptr, nullPtr)

import System.Posix.Directory.Internals  (DirStream           (DirStream), CDir, CDirent)

import UnliftIO.Exception                (bracketOnError)
import Control.Exception.Base            (catch)
import System.IO.Error                   (isPermissionError)

import Control.Monad.Except              (runExceptT , ExceptT(..))

import FileSystem.RawFilePathUtils       (checkIfDir, concatRelativeFilePath, dtDir,concatAbsolutePath )






-- hehe viktig at vi burker safe call for alt som gjør IO
--  https://github.com/haskell/unix/issues/34


foreign import ccall safe "readdir"
  c_readdir :: Ptr CDir -> IO (Ptr CDirent)

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


-- the FFI boundary: c_readdir, c_name, c_type,
-- readDirEnt, DirError, traverseDirectoryContents,
-- openDirStreamPermissive, foldDirectoryTree_


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
          pure . Right . Just  $ DirContent{fileType = dType, name = dName}
         -- pure . Right . Just  $ (dType, dName)




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
                          -> AbsolutPath RawFilePath
                          -> m a
traverseDirectoryContents f s0 (AbsolutPath p) = do
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
            Left  errMsg                     -> throwIO errMsg
            Right Nothing                    -> pure acc          -- Om den er kommeet til enden av dir
            Right (Just  dc@DirContent{..}) -> if name == "." || name == ".."
                                                then loop run acc dirp
                                                else do
                                                  acc' <- run $ f acc dc
                                                  loop run acc' dirp


foldDirectoryTree
    :: forall a . (a -> FilePaths -> DirContent -> IO a)  --  forall scoopes a in hele func function
    -> a -- 
    -> FilePaths
    -> IO a
foldDirectoryTree foldFunc acc paths = do
    isDir <- checkIfDir (absoluteFilePath paths)
    if not isDir
        then pure acc
        else traverseDirectoryContents innerloop acc (absoluteFilePath paths )
    where
        innerloop  :: a -> DirContent -> IO a
        innerloop currentAcc dc@DirContent{..} = do
            let newAbsPath = concatAbsolutePath     (absoluteFilePath paths) (pure name)
            let newRelPath = concatRelativeFilePath (relativeFilePath paths) (pure name) Nothing
            let isDir = fileType == dtDir
            nextAcc <- foldFunc currentAcc paths dc

            if not isDir
                then pure nextAcc
                else foldDirectoryTree foldFunc nextAcc (FilePaths{absoluteFilePath = newAbsPath, relativeFilePath = newRelPath})







