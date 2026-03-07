{- HLINT ignore "Use if" -}
{-# LANGUAGE OverloadedStrings #-}
module TreveseFunctions where

import System.Posix.Directory.Foreign

import System.Posix.Directory.ByteString

import qualified Data.ByteString.Char8 as BS
import System.Posix.ByteString.FilePath
import Unsafe.Coerce (unsafeCoerce)
import Foreign.C.Error
import Foreign.C.String
import Foreign.C.Types
import Foreign.Marshal.Alloc (alloca,allocaBytes) 
import UnliftIO (MonadUnliftIO, withRunInIO)
import System.Posix.Files.ByteString (isDirectory, getFileStatus)
import Control.Monad.IO.Class

import qualified Data.ByteString.Char8 as BC
import System.Posix.Directory.ByteString as PosixBS

import System.IO.Error

 
import UnliftIO.Exception


import Foreign.Ptr as PTR
import Foreign.Storable
import System.Posix (isDirectory, terminalMode)
import System.Posix.Directory.Internals (DirStream(DirStream))





foreign import ccall safe "__hscore_readdir"
  c_readdir  :: Ptr CDir -> Ptr (Ptr CDirent) -> IO CInt

foreign import ccall unsafe "__hscore_free_dirent"
  c_freeDirEnt  :: Ptr CDirent -> IO ()

foreign import ccall unsafe "__hscore_d_name"
  c_name :: Ptr CDirent -> IO CString

foreign import ccall unsafe "__posixdir_d_type"
  c_type :: Ptr CDirent -> IO DirType

foreign import ccall "realpath"
  c_realpath :: CString -> CString -> IO CString


--- unsafe forløping

-- men 

type CDir = ()
type CDirent = ()

unpackDirStream :: DirStream -> Ptr CDir
unpackDirStream = unsafeCoerce

packDirStream :: Ptr CDir -> DirStream
packDirStream = unsafeCoerce


readDirEnt :: DirStream -> IO (Maybe (DirType, RawFilePath) )
readDirEnt dir = do
  alloca $ \ptr_dEnt  -> loop ptr_dEnt
    where
    loop ptr_dEnt = do
        let dirp = unpackDirStream  dir
        _ <- resetErrno
        r <- c_readdir dirp ptr_dEnt  --
        case r == 0 of
            True -> do
                dEnt <- peek ptr_dEnt   -- leser innholder på det  somer på peker
                if dEnt == PTR.nullPtr  -- s
                    then pure Nothing --  pure (dtUnknown, BS.empty) 
                    else do
                        dName <- c_name dEnt >>= (\l -> peekFilePath l)
                        dType <- c_type dEnt
                        c_freeDirEnt dEnt
                        pure $ Just (dType, dName)
            False -> do
                errno <- getErrno
                if errno == eINTR   --kjører loopen på dersom error er en intetuped systcall 
                    then loop ptr_dEnt 
                    else do
                        let (Errno errorCode) = errno -- patter matcher og henter errorCode 
                        if errorCode == 0 
                            then pure  Nothing --(dtUnknown, BS.empty)
                            else throwErrno "readDirEnt"


readAnEntireDir :: BC.ByteString -> IO [(DirType,RawFilePath)]
readAnEntireDir p = do
    stream <- openDirStream  p
    restOfTheDir <- rest stream []
    closeDirStream  stream 
    pure restOfTheDir 
    where 
        rest :: DirStream -> [(DirType,RawFilePath)] -> IO [(DirType,RawFilePath)]
        rest s lst = do 
            readContent <- readDirEnt s 
            case readContent of
                Nothing    -> pure lst 
                (Just elm) -> rest s (elm : lst)




treverseDir :: [RawFilePath] -> RawFilePath ->  IO [RawFilePath]
treverseDir acc filePath = topLoop
    where 
    topLoop = do
        isDir <- liftIO $ isDirectory <$> getFileStatus filePath 
        case isDir of
        pure []



modifyIOErrorUnliftIO :: (MonadUnliftIO m) => (IOError -> IOError) -> m a -> m a
modifyIOErrorUnliftIO f action =
  withRunInIO $ \runInIO -> do
    modifyIOError f (runInIO action)


traverseDirectoryContents ::   RawFilePath -> IO [(DirType,RawFilePath)]
traverseDirectoryContents p =
  modifyIOErrorUnliftIO
    ((`ioeSetFileName` (BS.unpack p)) . -- feilmleidng de en den skal kasete
     (`ioeSetLocation` "System.Posix.Directory.Traversals.traverseDirectoryContents")) $ do -- feilmeldinge 2 den skal kaste
    bracket
      (liftIO $ PosixBS.openDirStream path)
      (liftIO . PosixBS.closeDirStream)
      (\dirp -> loop [] dirp)
  where
    loop :: [(DirType, RawFilePath)] -> DirStream -> IO [(DirType,RawFilePath)]
    loop arr dirp = do
        dirAnd <-  liftIO $ readDirEnt dirp
        case dirAnd of
            Nothing  -> pure arr
            Just t@(_typ,e) -> do
                if e == "." || e  == ".." then loop arr dirp
                else loop (t : arr) dirp




path :: BC.ByteString
path =  BC.pack  "/Users/martineldeknutsen/Dev/UiB/inf221/"



testA :: IO [Bool]
testA = map ((==dtDir) . fst) <$> readAnEntireDir path

testB = traverseDirectoryContents path





 







 













