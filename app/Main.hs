module Main where

import ParseInput (parseLamdaSearch, runMyParser)

import TraverselsFunctions (treverseDirWithSettings)
import TraversalSettings (
      FilterFlags(..), SearchSetting(..), convertString,  )

import PrintFunctions (
      printResults)

import System.IO (
     stdout, BufferMode(LineBuffering), hSetBuffering )


main :: IO ()
main = do
     hSetBuffering stdout LineBuffering 
     input  <- getLine 
     output <- case runMyParser parseLamdaSearch input of
        Nothing -> TraverselsFunctions.treverseDirWithSettings searchSettings
        Just ss -> TraverselsFunctions.treverseDirWithSettings ss
     printResults output

path :: FilePath
path  = "/Users/martineldeknutsen/Dev/UiB/inf221/semesterProjekt/"

allPath :: [FilePath]
allPath = [path]

defaultFlags1 :: FilterFlags
defaultFlags1 = FilterFlags {
    regxPattern = Nothing
  , exclude     = Nothing
  , extention   = Just $ convertString "java"
  , hideHidden  = False
}

defaultFlags2 :: FilterFlags
defaultFlags2 = FilterFlags {
    regxPattern = Nothing
  , exclude     = Nothing
  , extention   = Nothing
  , hideHidden  = True
}

searchSettings :: SearchSetting
searchSettings = SearchSetting {
      searchPaths    =  allPath
    , applyedCommand =  Nothing
    , filters        =  defaultFlags2
}

