
{-# LANGUAGE OverloadedStrings #-}
module PrintFunctions (printResults ) where

import Prelude hiding (reverse,break,span ) 
import TraverselsFunctions                   (DirContent) 
import qualified Data.ByteString.Char8 as BS (unpack, pack )
import System.Posix.Directory.Foreign        (dtLnk, dtDir)

import Data.ByteString(span,reverse )
import Data.ByteString.Internal(c2w)



import System.Console.ANSI
    ( setSGR,
      Color(Red),
      ColorIntensity(Vivid),
      ConsoleLayer(Foreground),
      SGR(Reset, SetColor) 
      )
import System.Console.ANSI.Codes (setSGRCode)

printResults :: [DirContent] -> IO ()
printResults contents = do
    setSGR [SetColor Foreground Vivid Red]
    mapM_ printDirContent $ filter ((/= dtDir ) . fst) contents 
    setSGR [Reset]

-- | printer et Enkelt DirContent element
printDirContent :: DirContent -> IO ()
printDirContent (_, a) = do
    let (post,pre) = span (/= c2w '/') $ reverse a
    putStrLn $ BS.unpack pre
        <> setSGRCode [SetColor Foreground Vivid Red]
        <> BS.unpack post
        <> setSGRCode [Reset]
    


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




