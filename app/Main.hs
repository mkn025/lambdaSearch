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



defaultFlags1 :: FilterFlags
defaultFlags1 = FilterFlags {
    regxPattern = Nothing
  , include     = Nothing
  , exclude     = Nothing
  , extention   = Just $ convertString "java"
  , hideHidden  = False

}


defaultFlags2 :: FilterFlags
defaultFlags2 = FilterFlags {

    regxPattern = Just $ convertString "fooBarFooBar"
  , include     = Nothing
  , exclude     = Nothing
  , extention   = Nothing
  , hideHidden  = False
}





