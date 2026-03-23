module Main where

import TraverselsFunctions (treverFilePath)
import FileTraversal
import PrintFunctions


path = "/Users/martineldeknutsen/Dev/UiB/"
path :: String

main :: IO ()
main = do
    lst <- treverFilePath path defaultFlags2
    printResults lst

defaultFlags2 :: FilterFlags
defaultFlags2 = FilterFlags {
    regxPattern = Just ".*\\.java"
  , include     = Nothing
  , exclude     = Nothing
  , extention   = Nothing
  , hideHidden  = True

  }





