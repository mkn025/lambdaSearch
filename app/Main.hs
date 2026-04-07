module Main where

import TraverselsFunctions (
    treverFilePath , treverseDirWithSettings , applyFunctionToPath )


import TraversalSettings(
      FilterFlags(..), SearchSetting(..), convertString )

import PrintFunctions (
      printResults)

import System.IO (
     stdout, BufferMode(LineBuffering), hSetBuffering )

main :: IO ()
main = do
        hSetBuffering stdout LineBuffering
        out <- treverseDirWithSettings  ss
        printResults out



path :: FilePath
path  = "/Users/martineldeknutsen/Dev/UiB/inf221/semesterProjekt/testMappe/"

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

ss :: SearchSetting
ss = SearchSetting {
      searchPaths    =  allPath
    , maxDepth       =  Nothing
    , applyedCommand =  Nothing
    , filters        =  defaultFlags2
}


