{-# OPTIONS_GHC -Wno-unused-top-binds #-}
module PrintFunctions (printResults,printResults_ ) where
import TraverselsFunctions                   (DirContent,FileInfomation(..)) 
import qualified Data.ByteString.Char8 as BS (unpack)
import System.Posix.Directory.Foreign        (dtLnk, dtDir)


import System.Posix.Terminal                 (queryTerminal)
import System.Posix.IO                       (stdOutput)
import System.Console.ANSI.Codes

    ( setSGRCode,
      Color(Red),
      ColorIntensity(Vivid),
      ConsoleLayer(Foreground),
      SGR(Reset, SetColor) )
import TraversalSettings (convertString, convertToString)



printResults :: [DirContent] -> IO ()
printResults contents = do
    mapM_ printDirContent $ filter ((/= dtDir ) . fst) contents 

-- | printer et Enkelt DirContent element
printDirContent :: DirContent -> IO ()
printDirContent = putStrLn . BS.unpack . snd   



printResults_ :: [FileInfomation] -> IO ()
printResults_ contents = do
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




    

-- | printer et Enkelt DirContent element
-- | Printer men legger til / for mappe
printDirContentWithType :: DirContent -> IO ()
printDirContentWithType (dirType, rawFilePath) = do
  let path = BS.unpack rawFilePath
  let marker = case dirType of
                 l | l == dtDir -> "/"  
                 l | l == dtLnk -> "@"  
                 _              -> ""   
  putStrLn $ path ++ marker

coloriseFileIfTTY :: IO (String -> String)
coloriseFileIfTTY = do
    tty <- queryTerminal stdOutput
    pure $ if tty then coloriseFile else id


coloriseFile :: String -> String
coloriseFile rfp =  setSGRCode [SetColor Foreground Vivid Red] <> rfp <> setSGRCode [Reset]

