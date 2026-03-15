module Main where

import TreveseFunctions (treverFilePath) 
import FileTreversal 



main :: IO ()
main = pure ()


defaultFlags2 :: FilterFlags
defaultFlags2 = FilterFlags {
    include     = Nothing
  , exclude     = Nothing
  , extention   = Just $ convertString  "pdf"
  , hidden      = True
  , fileOnly    = False
  }


testA = treverFilePath "/Users/martineldeknutsen/Dev/UiB/inf221/semesterProjekt/testMappe" defaultFlags2 







