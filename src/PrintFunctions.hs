
module PrintFunctions (printResults ) where
import TraverselsFunctions 
import System.IO 
import qualified Data.ByteString.Char8 as BS  (unpack )

import System.Posix.Directory.Foreign (dtLnk,dtDir )




printResults :: [DirContent] -> IO ()
printResults contents = do
    hSetBuffering stdout LineBuffering
    mapM_ printDirContentWithType contents

printDirContent :: DirContent -> IO ()
printDirContent (dirType, rawFilePath) = do
  let path = BS.unpack rawFilePath
  putStrLn path  -- Simple: just print the path

printDirContentWithType :: DirContent -> IO ()
printDirContentWithType (dirType, rawFilePath) = do
  let path = BS.unpack rawFilePath
  let marker = case dirType of
                 dt | dt == dtDir -> "/"  -- directories end with /
                 dt | dt == dtLnk -> "@"  -- symlinks end with @
                 _               -> ""     -- files have no markerkkkk
  putStrLn $ path ++ marker




