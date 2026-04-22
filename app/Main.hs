module Main where

import SearchTUI           (mainTUI)
import ParseInput          (runParserIO)
import System.Environment  (getArgs )

import TraverselsFunctions (treverseDirWithSettings)
import PrintFunctions      (printResults)
import System.IO           (stdout, BufferMode(LineBuffering), hSetBuffering )

main :: IO ()
main = do
     hSetBuffering stdout LineBuffering
     input  <- getArgs
     actOnInput input


runTUI :: IO ()
runTUI = mainTUI

runCLi :: [String] -> IO ()
runCLi args = do
     let inpString =  concatMap ( ' ' :) args
     ss     <- runParserIO inpString
     output <- treverseDirWithSettings ss
     printResults output

actOnInput :: [String] ->  IO()
actOnInput []                           = runCLi []
actOnInput ((=="TUI") . head -> True)   = runTUI
actOnInput x                            = runCLi x











