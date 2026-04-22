module Main where

import System.Environment  (getArgs )

import ParseInput          (runParserIO)

import TraverselsFunctions (treverseDirWithSettings)
import PrintFunctions      (printResults)
import System.IO           (stdout, BufferMode(LineBuffering), hSetBuffering )

main :: IO ()
main = do
     hSetBuffering stdout LineBuffering 
     input  <- getArgs 
     let inpString =  concatMap ( ' ' :) input
     ss     <- runParserIO inpString
     output <- treverseDirWithSettings ss
     printResults output




