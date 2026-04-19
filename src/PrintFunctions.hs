{-# OPTIONS_GHC -Wno-unused-top-binds #-}
module PrintFunctions (printResults ) where

import TraverselsFunctions                   (DirContent) 
import qualified Data.ByteString.Char8 as BS (unpack)
import System.Posix.Directory.Foreign        (dtLnk, dtDir)


printResults :: [DirContent] -> IO ()
printResults contents = do
    mapM_ printDirContent $ filter ((/= dtDir ) . fst) contents 

-- | printer et Enkelt DirContent element
printDirContent :: DirContent -> IO ()
printDirContent = putStrLn . BS.unpack . snd   

-- | printer et Enkelt DirContent element
-- | Printer men legger til / for mappe
printDirContentWithType :: DirContent -> IO ()
printDirContentWithType (dirType, rawFilePath) = do
  let path = BS.unpack rawFilePath
  let marker = case dirType of
                 l | l == dtDir -> "/"  
                 l | l == dtLnk -> "@"  
                 _              -> ""   
  putStrLn $ path ++ marker

