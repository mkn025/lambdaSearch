module Main (main) where

import Cli.Parser         (runParserIO)
import System.Environment (getArgs)
import Output.Print       (printResults)
import Core.PrintTypes    (PrintSettings (..), PathType(..), OutputColor(..))
import FileSystem.Search  (treverseDirWithSettings)



defPrintSettings :: PrintSettings
defPrintSettings = PrintSettings {
          pathType   = RelativeFilePath
        , matchColor = Greeny
        }

main :: IO ()
main = do
     input  <- getArgs
     actOnInput input

actOnInput :: [String] ->  IO ()
actOnInput [] = runCLi []
actOnInput x  = runCLi x


runCLi :: [String] -> IO ()
runCLi args = do
     ss     <- runParserIO $ unwords args 
     output <- treverseDirWithSettings ss
     printResults defPrintSettings output











