module Main (main) where

import Cli.Parser         (runParserIO)
import System.Environment (getArgs)
import Output.Print       (printResults)
import Core.SettingsTypes (ProgramSettings(..))
import FileSystem.Search  (treverseDirWithSettings)




main :: IO ()
main = do
     input  <- getArgs
     actOnInput input

actOnInput :: [String] ->  IO ()
actOnInput [] = runCLi []
actOnInput x  = runCLi x




runCLi :: [String] -> IO ()
runCLi args = do
     prgs  <- runParserIO $ unwords args 
     let ss =  searchSetting  prgs
     let ps =  printSettings  prgs
     output <- treverseDirWithSettings  ss
     printResults ps output











