
module PrintFunctions (printResults ) where
import TraverselsFunctions ( DirContent ) 
import System.IO ( stdout, BufferMode(LineBuffering), hSetBuffering ) 
import qualified Data.ByteString.Char8 as BS(unpack )
import System.Posix.Directory.Foreign (dtLnk,dtDir )
import System.Console.ANSI


-- | Printer resultatet, bruker linebuffer slik at søkeresultaene skal bli synlig forløpende

printResults :: [DirContent] -> IO ()
printResults contents = do
    hSetBuffering stdout LineBuffering 
    setSGR [SetColor Foreground Vivid Red]
    mapM_ printDirContent $ filter ((/= dtDir ) . fst) contents 


-- | printer et Enkelt DirContent element
printDirContent :: DirContent -> IO ()
printDirContent (_ , rawFilePath) = do
  let path = BS.unpack rawFilePath
  putStrLn path  



-- | printer et Enkelt DirContent element
-- | Printer men legger til / for mappe
printDirContentWithType :: DirContent -> IO ()
printDirContentWithType (dirType, rawFilePath) = do
  let path = BS.unpack rawFilePath
  let marker = case dirType of
                 dt | dt == dtDir -> "/"  -- directories end with /
                 dt | dt == dtLnk -> "@"  -- symlinks end with @
                 _               -> ""     -- files have no markerkkkk
  putStrLn $ path ++ marker




