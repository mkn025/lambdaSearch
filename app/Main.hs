module Main where

import System.Environment(getArgs )

import ParseInput (parseLamdaSearch, runMyParser)

import TraverselsFunctions (treverseDirWithSettings)
import TraversalSettings (
      FilterFlags(..), SearchSetting(..), )

import PrintFunctions (
      printResults)

import System.IO (
     stdout, BufferMode(LineBuffering), hSetBuffering )


main :: IO ()
main = do
     hSetBuffering stdout LineBuffering 
     --input  <- getArgs 
     --let inpString =  concatMap ( ' ' :) input
     imp <- getLine 
     output <- case runMyParser parseLamdaSearch imp of
        Just ss -> TraverselsFunctions.treverseDirWithSettings ss
        Nothing -> TraverselsFunctions.treverseDirWithSettings dss
     printResults output

path :: FilePath
path  = "/Users/martineldeknutsen/Dev/UiB/inf221/semesterProjekt/"

allPath :: [FilePath]
allPath = [path]


defaultFlags :: FilterFlags
defaultFlags = FilterFlags {
    regxPattern = Nothing
  , exclude     = Nothing
  , extention   = Nothing
  , hideHidden  = True
}

dss :: SearchSetting
dss = SearchSetting {
      searchPaths    =  allPath
    , applyedCommand =  Nothing
    , filters        =  defaultFlags
}

