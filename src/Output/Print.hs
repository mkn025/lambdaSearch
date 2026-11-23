{- HLINT ignore "Use <$>" -}
module Output.Print (printResults) where

-- Typer
import Core.TraversalTypes (
      FileInfomation(..)
    , DirContent    (..)
    , FilePaths     (..)
    )
import Core.PrintTypes    (
      OutputColor  (..)
    , PathType     (..)
    , PrintSettings(..)
    )

import System.Console.ANSI.Codes (
        setSGRCode
      , Color          (Green, Red, Blue)
      , ColorIntensity (Vivid)
      , ConsoleLayer   (Foreground)
      , SGR            (Reset, SetColor)
      )



import FileSystem.RawFilePathUtils (unpackRelativPath , unpackAbsolutPath)
import System.Posix.Terminal       (queryTerminal)
import System.Posix.IO             (stdOutput)
import Core.Filters                (convertToString)

import Data.Bool                   (bool )
import Control.Monad               (forM_)


-- | Printer all filene som er funnet 
--  mapper og kaster output for hele listen
printResults :: PrintSettings ->  [FileInfomation] -> IO ()
printResults ps contents = forM_ contents  =<< printFileColor ps 

printFileColor :: PrintSettings -> IO (FileInfomation -> IO ())
printFileColor ps = pure  . printFileInformation ps =<< coloriseFileIfTTY

-- | Printer et Enkelt FileInfomation element. Og bruker fargefunksjoen på bare filen
printFileInformation :: PrintSettings -> (OutputColor -> String -> String) -> FileInfomation -> IO ()
printFileInformation PrintSettings{..} colorFunc fi = handleInfo fi
        where
        handleInfo (fileNameInfo  -> Nothing) = pure ()
        handleInfo (fileNameInfo  -> Just dc) = putStrLn colorisedPath
                where
                filePath      = getFilePath pathType fi
                filename      = convertToString . name $ dc
                colorisedPath = filePath <> ( '/' : colorFunc matchColor filename)

getFilePath :: PathType -> FileInfomation -> String
getFilePath  RelativeFilePath    =  unpackRelativPath . fmap convertToString . relativeFilePath . filePaths
getFilePath  AbsolutPathFilePath =  unpackAbsolutPath . fmap convertToString . absoluteFilePath . filePaths

-- | Legger på ansi codes på dersom du skal sende den til terminal. Ellers er det bare id
coloriseFileIfTTY :: IO (OutputColor -> String -> String)
coloriseFileIfTTY =  bool (pure coloriseFile) (pure (const id)) =<< queryTerminal stdOutput

-- | wrapper ani scape codes på en streng
coloriseFile :: OutputColor  ->  String -> String
coloriseFile  Greeny  = (<> setSGRCode [Reset]) . (setSGRCode [SetColor Foreground Vivid Green] <>)
coloriseFile  Redish  = (<> setSGRCode [Reset]) . (setSGRCode [SetColor Foreground Vivid Red]   <>)
coloriseFile  Blueish = (<> setSGRCode [Reset]) . (setSGRCode [SetColor Foreground Vivid Blue]  <>)






