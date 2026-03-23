{-# LANGUAGE OverloadedStrings #-}
{- HLINT ignore "Use let" -}
{- HLINT ignore "Avoid lambda" -}
{- HLINT ignore "Use if" -}

module TraverselsFunctions (treverFilePath,DirContent) where

import System.Posix.Directory.Foreign

import System.Posix.ByteString.FilePath
import Foreign.C.Error
import Foreign.C.String
import Foreign.C.Types

import Foreign.Marshal.Alloc (alloca)
import UnliftIO (MonadUnliftIO, withRunInIO)
import System.Posix.Files.ByteString (isDirectory, getFileStatus)

import Control.Monad.IO.Class ( MonadIO(liftIO) )

import qualified Data.ByteString.Char8 as BS  (unpack,pack )
import System.Posix.Directory.ByteString as PosixBS 


import System.IO.Error
import System.Posix.FilePath ((</>))

import UnliftIO.Exception ( bracket )

import Foreign.Ptr as PTR ( Ptr, nullPtr )
import Foreign.Storable   ( Storable(peek) )
import System.Posix.Directory.Internals (DirStream(DirStream), CDir, CDirent )

import FileTraversal (

      FilterFlags
    , getAllowFilter
    , getDisallowFilter
    , getHiddenFilter
    , getExtentionFilter
    , compileRegexFilter
    , getRexPattern
    )


type DirContent = (DirType,RawFilePath)


-- Lager Haskll funksjoner igjennom FFI
foreign import ccall safe "__hscore_readdir"
  c_readdir  :: Ptr CDir -> Ptr (Ptr CDirent) -> IO CInt

foreign import ccall unsafe "__hscore_free_dirent"
  c_freeDirEnt  :: Ptr CDirent -> IO ()

foreign import ccall unsafe "__hscore_d_name"
  c_name :: Ptr CDirent -> IO CString

foreign import ccall unsafe "__posixdir_d_type"
  c_type :: Ptr CDirent -> IO DirType


-- om du peeker CDir så får du CDirent

unpackDirStream :: DirStream -> Ptr CDir
unpackDirStream (DirStream a) = a


readDirEnt :: DirStream -> IO (Maybe DirContent)
readDirEnt dir = do
  alloca $ \ptr_dEnt  -> loop ptr_dEnt
    where
    loop ptr_dEnt = do
        let dirp = unpackDirStream  dir
        _ <- resetErrno
        r <- c_readdir dirp ptr_dEnt  --
        case r == 0 of
            True -> do
                dEnt <- peek ptr_dEnt   -- leser innholder på det  somer på peker, dererferer
                if dEnt == PTR.nullPtr  -- s
                    then pure Nothing   --  pure (dtUnknown, BS.empty) 
                    else do
                        dName <- c_name dEnt >>= (\l -> peekFilePath l) -- bare lamdda siden det er letter å lese
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



modifyIOErrorUnliftIO :: (MonadUnliftIO m) => (IOError -> IOError) -> m a -> m a
modifyIOErrorUnliftIO f action =
  withRunInIO $ \runInIO -> do
    modifyIOError f (runInIO action)

traverseDirectoryContents :: (MonadUnliftIO m)
                          => (a -> DirContent -> m a)  -- fold funksjon
                          -> a                          -- accumulator
                          -> RawFilePath                -- directory path
                          -> m a
traverseDirectoryContents f s0 p =
  modifyIOErrorUnliftIO
    ((`ioeSetFileName` BS.unpack p)  .
     (`ioeSetLocation` "System.Posix.Directory.Traversals.traverseDirectoryContents")) $ do
    bracket
      (liftIO $ PosixBS.openDirStream p)
      (liftIO . PosixBS.closeDirStream)
      (\dirp -> loop s0 dirp)
  where
    loop acc dirp = do  -- acc er listen din
        dirAnd <- liftIO $ readDirEnt dirp
        case dirAnd of
            Nothing          -> pure acc -- stoper dersom dir ikke klarer å lese. 
            Just content@(_typ, e) ->
                if e == "." || e == ".."
                    then loop acc dirp -- gi 
                    else do
                        -- altså bruk funkjsonen acc og t og gi oss den nyye acc.
                        -- løft med do notasjon
                        -- og kast tilbake i loopen
                        acc' <- f acc content
                        loop acc' dirp




treversRecursively :: FilterFlags -> [DirContent] -> RawFilePath -> IO [DirContent]
treversRecursively sf arr p =  topLoop

    where

    reg = seq const $ compileRegexFilter sf
    topLoop :: IO [DirContent]
    topLoop = do
        isDir <- liftIO $ isDirectory <$> getFileStatus p
        if not isDir  -- bruker negasjonen slik at koden skal se bedre ut
            then pure arr
            else traverseDirectoryContents innerLoop arr p
        where
            innerLoop :: [DirContent] -> DirContent -> IO [DirContent]
            innerLoop acc t@(typ,file) = do
                let fullpath = p </> file --legg sammen slik at vi er inne på riktig sti
                isDir <- liftIO . pure $ typ == dtDir
                if not isDir
                    then do

                        rg  <- pure $ getRexPattern      reg file

                        af  <- pure $ getAllowFilter     sf file 
                        df  <- pure $ getDisallowFilter  sf file 
                        hf  <- pure $ getHiddenFilter    sf file 
                        ef  <- pure $ getExtentionFilter sf file 
                        
                        if and [rg, af , df ,ef ,hf]  
                            then pure ((typ,fullpath):acc)
                            else pure acc
                    else treversRecursively sf (t : acc) fullpath






treverFilePath :: FilePath -> FilterFlags -> IO [DirContent]
treverFilePath fp sf = treversRecursively sf [] $ BS.pack fp



