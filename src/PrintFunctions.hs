module PrintFunctions (printResults) where


import System.Posix.Terminal     (queryTerminal     )
import TraversalFunctions        (FileInfomation_(..), DirContent(..),RelativPath(..) , FilePaths (relativeFilePath_) ) 
import System.Posix.IO           (stdOutput      )
import TraversalSettings         (convertToString)

import System.Console.ANSI.Codes (
        setSGRCode
      , Color          (Green)
      , ColorIntensity (Vivid)
      , ConsoleLayer   (Foreground)
      , SGR            (Reset, SetColor)
      )


-- | Printer all filene som er funnet 
--  mapper og kaster output for hele listen
printResults :: [FileInfomation_] -> IO ()
printResults contents = do
    color <- coloriseFileIfTTY  
    mapM_ (printFileInformation color) contents  -- mapM_ siden den bare skal >> ikke >>= basicly

-- | Printer et Enkelt FileInfomation element. Og bruker fargefunksjoen på bare filen
printFileInformation :: (String -> String) -> FileInfomation_ -> IO ()
printFileInformation colorFunc fi = do
        case fileNameInfo_ fi of
            Nothing -> pure ()
            Just dc  -> do
                let (RelativPath fp) = convertToString  <$> ( relativeFilePath_ . filePaths)  fi
                let filename         = convertToString . name $ dc
                let colorisedPath    = fp <> ( '/' : colorFunc filename)
                putStrLn colorisedPath 

-- | Legger på ansi codes på dersom du skal sende den til terminal. Ellers er det bare id
coloriseFileIfTTY :: IO (String -> String)
coloriseFileIfTTY = do
    tty <- queryTerminal stdOutput -- burkes til å finne ut om vi skal til terminal eller til en pipe
    pure $ if tty
           then coloriseFile
           else id

-- | wrapper ani scape codes på en streng
coloriseFile :: String -> String
coloriseFile = (<> setSGRCode [Reset]) . (setSGRCode [SetColor Foreground Vivid Green] <>)






