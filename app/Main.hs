module Main (main) where

import SearchTUI           (mainTUI)
import ParseInput          (runParserIO)
import System.Environment  (getArgs)

import TraverselsFunctions (treverseDirWithSettings)
import PrintFunctions      (printResults)

main :: IO ()
main = do
     input  <- getArgs
     actOnInput input



actOnInput :: [String] ->  IO()
actOnInput []                           = runCLi []
actOnInput ((=="TUI") . head -> True)   = runTUI
actOnInput x                            = runCLi x

runTUI :: IO ()
runTUI = mainTUI

runCLi :: [String] -> IO ()
runCLi args = do
     ss     <- runParserIO $ unwords args 
     output <- treverseDirWithSettings ss
     printResults output











