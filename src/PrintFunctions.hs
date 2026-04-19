{-# OPTIONS_GHC -Wno-unused-top-binds #-}
module PrintFunctions (printResults) where
import TraverselsFunctions                   (FileInfomation(..)) 


import System.Posix.Terminal                 (queryTerminal)
import System.Posix.IO                       (stdOutput)
import System.Console.ANSI.Codes

    ( setSGRCode,
      Color(Red),
      ColorIntensity(Vivid),
      ConsoleLayer(Foreground),
      SGR(Reset, SetColor) )
import TraversalSettings (convertToString)






printResults :: [FileInfomation] -> IO ()
printResults contents = do
    color <- coloriseFileIfTTY  
    mapM_ (printFileInformation color)   contents 


-- | printer et Enkelt DirContent element
printFileInformation :: (String -> String) -> FileInfomation -> IO ()
printFileInformation colorFunc fi = do
        case dirContent fi of
            Nothing -> pure ()
            Just dc  -> do
                let fp = convertToString . filePath $ fi
                let fn = convertToString . snd      $ dc
                putStrLn $ fp <> ( '/' : colorFunc fn)


coloriseFileIfTTY :: IO (String -> String)
coloriseFileIfTTY = do
    tty <- queryTerminal stdOutput
    pure $ if tty then coloriseFile else id


coloriseFile :: String -> String
coloriseFile rfp =  setSGRCode [SetColor Foreground Vivid Red] <> rfp <> setSGRCode [Reset]

