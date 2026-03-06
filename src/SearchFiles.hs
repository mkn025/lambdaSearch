{- HLINT ignore "Use if" -}
module SearchFiles where


import Control.Monad.State
import System.Posix.ByteString.FilePath
import System.Posix.Directory.ByteString
import qualified Data.ByteString as BS
import qualified Data.ByteString.Char8 as BC

import System.Posix.Directory.Traversals 
import System.Posix (FileOffset)



-- Bruker heller ByteString siden det er mye kjappere enn strenger

traverseDir :: Maybe BS.ByteString -> IO [ Maybe BS.ByteString]
traverseDir Nothing  = pure []
traverseDir (Just p) = do
    stream <- openDirStream p
    allFile <- readRest stream []
    closeDirStream  stream 
    pure allFile 
    where
        readRest :: DirStream -> [Maybe BS.ByteString] -> IO [Maybe BS.ByteString]
        readRest s lst = do
            nextElm <- readDirStreamMaybe s
            p <- realpath  $ (\(Just a) -> a) nextElm 

            case nextElm of 
                Nothing  -> pure lst
                (Just _) -> readRest s $ nextElm : lst




type FolderState a = StateT FolderAndContent IO a




data FolderAndContent = FolderAndContent {
      allFiles  :: [RawFilePath]
    , fileCount :: Integer
    , totalSize :: FileOffset
    } deriving (Eq,Show)



    



--- BARE TESTING  ---

-- (s -> RawFilePath -> m s)
update :: [RawFilePath] -> RawFilePath -> IO [RawFilePath]
update paths p = pure (p : paths)

testC :: IO [RawFilePath]
testC = traverseDirectory  update []  $ BC.pack  "w"


path :: Maybe BC.ByteString
path = Just $ BC.pack  "/Users/martineldeknutsen/Dev/UiB/inf221/"

testA :: IO [Maybe BC.ByteString]
testA = traverseDir path


