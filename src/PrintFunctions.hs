module PrintFunctions (printResults) where

import TraverselsFunctions   (FileInfomation(..)) 

import System.Posix.Terminal (queryTerminal)
import System.Posix.IO       (stdOutput)
import TraversalSettings     (convertToString)


import System.Console.ANSI.Codes (
        setSGRCode
      , Color         (Green)
      , ColorIntensity(Vivid)
      , ConsoleLayer  (Foreground)
      , SGR           (Reset, SetColor)
      )


printResults :: [FileInfomation] -> IO ()
printResults contents = do
    color <- coloriseFileIfTTY  
    mapM_ (printFileInformation color) contents 

-- | Printer et Enkelt DirContent element
printFileInformation :: (String -> String) -> FileInfomation -> IO ()
printFileInformation colorFunc fi = do
        case dirContent fi of
            Nothing -> pure ()
            Just dc  -> do
                let fp   = convertToString . filePath $ fi
                let fn   = convertToString . snd      $ dc
                let path = fp <> ( '/' : colorFunc fn)
                putStrLn path 


-- | Printer et Enkelt DirContent element
coloriseFileIfTTY :: IO (String -> String)
coloriseFileIfTTY = do
    tty <- queryTerminal stdOutput
    pure $ if tty
           then coloriseFile
           else id

coloriseFile :: String -> String
coloriseFile rfp = setSGRCode [SetColor Foreground Vivid Green] <> rfp <> setSGRCode [Reset]

