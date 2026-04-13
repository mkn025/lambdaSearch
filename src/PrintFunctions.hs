module PrintFunctions (printResults ) where


import TraverselsFunctions                   (DirContent) 
import qualified Data.ByteString.Char8 as BS (unpack)
import System.Posix.Directory.Foreign        (dtLnk, dtDir)

import System.Console.ANSI
    ( setSGR,
      Color(Red),
      ColorIntensity(Vivid),
      ConsoleLayer(Foreground),
      SGR(Reset, SetColor) 
      )

printResults :: [DirContent] -> IO ()
printResults contents = do
    setSGR [SetColor Foreground Vivid Red]
    mapM_ printDirContent $ filter ((/= dtDir ) . fst) contents 
    setSGR [Reset]


-- | printer et Enkelt DirContent element
printDirContent :: DirContent -> IO ()
printDirContent = putStrLn . BS.unpack . snd   

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




