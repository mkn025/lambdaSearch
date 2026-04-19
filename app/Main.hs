module Main where

import System.Environment(getArgs )

import ParseInput (runParserIO)

import TraverselsFunctions (treverseDirWithSettings,tester3)
import TraversalSettings (
      Arguments(..), SearchSetting(..), convertString, )

import PrintFunctions (
      printResults, printResults_ )

import System.IO (
     stdout, BufferMode(LineBuffering), hSetBuffering )


main :: IO ()
main = do
     hSetBuffering stdout LineBuffering 
     input  <- getArgs 
     let inpString =  concatMap ( ' ' :) input
     ss     <- runParserIO inpString
     output <- treverseDirWithSettings ss
     printResults output


testNew = do
    x <- tester3  defaultFlags (convertString  path)
    printResults_ x



path :: FilePath
path  = "/Users/martineldeknutsen/Dev/UiB/inf221/semesterProjekt/"

allPath :: [FilePath]
allPath = [path]

defaultFlags :: Arguments
defaultFlags = Arguments {
    regxPattern    = Just "Parse"
  , exclude        = Nothing
  , extention      = Nothing
  , hideHidden     = True
  , applyedCommand = Nothing
}

dss :: SearchSetting
dss = SearchSetting {
      searchPaths    =  Nothing
    , arguments      =  defaultFlags 
}

