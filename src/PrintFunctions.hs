module PrintFunctions (printResults, PrintSettings(..),PathType(..), OutputColor(..) ) where

import System.Posix.Terminal     (queryTerminal  )
import System.Posix.IO           (stdOutput      )
import TraversalSettings         (convertToString)

import TraversalFunctions        ( 
                                   FileInfomation(..)
                                 , DirContent    (..)
                                 , FilePaths     (..)
                                 , unpackRelativPath
                                 , unpackAbsolutPath 
                                 ) 

import System.Console.ANSI.Codes (
        setSGRCode
      , Color          (Green, Red, Blue)
      , ColorIntensity (Vivid)
      , ConsoleLayer   (Foreground)
      , SGR            (Reset, SetColor)
      )


data PathType = RelativeFilePath | AbsolutPathFilePath 
    deriving (Eq,Show)

data OutputColor = Redish | Greeny | Blueish
    deriving (Eq, Show)

data PrintSettings = PrintSettings{
      pathType   :: PathType
    , matchColor :: OutputColor
    } deriving (Eq,Show)


-- | Printer all filene som er funnet 
--  mapper og kaster output for hele listen
printResults :: PrintSettings ->  [FileInfomation] -> IO ()
printResults ps contents = do
    color <- coloriseFileIfTTY  
    mapM_ (printFileInformation ps color) contents  -- mapM_ siden den bare skal >> ikke >>= basicly


-- | Printer et Enkelt FileInfomation element. Og bruker fargefunksjoen på bare filen
printFileInformation :: PrintSettings -> (OutputColor -> String -> String) -> FileInfomation -> IO () 
printFileInformation PrintSettings{..} colorFunc fi = do
        case fileNameInfo fi of
            Nothing -> pure ()
            Just dc  -> do
                let fp            = getFilePath pathType fi
                let filename      = convertToString . name $ dc
                let colorisedPath = fp <> ( '/' : colorFunc matchColor filename)
                putStrLn colorisedPath 


getFilePath :: PathType -> FileInfomation -> String
getFilePath  RelativeFilePath    = unpackRelativPath  . fmap convertToString . relativeFilePath . filePaths  
getFilePath  AbsolutPathFilePath = unpackAbsolutPath  . fmap convertToString . absoluteFilePath . filePaths


-- | Legger på ansi codes på dersom du skal sende den til terminal. Ellers er det bare id
coloriseFileIfTTY :: IO (OutputColor -> String -> String)
coloriseFileIfTTY = do
    tty <- queryTerminal stdOutput -- burkes til å finne ut om vi skal til terminal eller til en pipe
    pure $ if tty
           then coloriseFile
           else (\_ a -> a)


-- | wrapper ani scape codes på en streng
coloriseFile :: OutputColor  ->  String -> String
coloriseFile  Greeny  = (<> setSGRCode [Reset]) . (setSGRCode [SetColor Foreground Vivid Green] <>)
coloriseFile  Redish  = (<> setSGRCode [Reset]) . (setSGRCode [SetColor Foreground Vivid Red]   <>)
coloriseFile  Blueish = (<> setSGRCode [Reset]) . (setSGRCode [SetColor Foreground Vivid Blue]  <>)






