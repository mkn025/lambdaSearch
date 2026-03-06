module FileTreversal where

import Control.Monad.State
import System.Posix.ByteString (RawFilePath)
import System.Posix.Directory.Traversals
import qualified Data.ByteString.Char8 as BC


-- Datastruktur som holder filnavnet


type FolderState a = StateT FolderAndContent IO a

data FolderAndContent = FolderAndContent {
      fileName :: RawFilePath
    , content  :: [RawFilePath]


    } deriving (Eq,Show)



type SeachFilters = [String]
data SearchSettings = SearchSettings {
      include    :: Maybe SeachFilters
    , exclude    :: Maybe SeachFilters -- 
    , depth      :: Maybe Integer      -- om Nothing. Så skal den gå så langt den vil
    , searchPath :: Maybe RawFilePath     -- om Nothing så søker den igjennom nåværende dir

    } deriving (Eq, Show)


flags :: SearchSettings 
flags = SearchSettings {
          include  = Nothing
        , exclude  = Nothing
        , depth  = Nothing
        , searchPath  = Nothing
    }

setFilename :: RawFilePath -> FolderAndContent -> FolderAndContent
setFilename n st = st {fileName = n}

setContent :: [RawFilePath]  -> FolderAndContent -> FolderAndContent
setContent c st = st {content = c}



update :: [RawFilePath] -> RawFilePath ->  IO [RawFilePath]
update lst f = pure $ f : lst

path :: RawFilePath
path =  BC.pack  "/Users/martineldeknutsen/Dev/UiB/inf221/"

testA = traverseDirectory update [] path 













