module TraversalSettings where


import System.Posix.ByteString (RawFilePath)
import qualified Data.ByteString.Char8 as BC (head,pack,tail)
import qualified Data.ByteString as BS (null)
import System.FilePath.ByteString (takeExtension)

import Text.Regex.TDFA
  ( Regex
  , ExecOption(..)
  , defaultCompOpt
  , defaultExecOpt
  , makeRegexOpts
  , matchTest
  )

-- Datastruktur som holder filnavnet
-- type FolderState a = StateT FolderAndContent IO a
type Extention     = RawFilePath
type SearchPattern = RawFilePath
type SearchFilters = [RawFilePath]

data Command =  Command{ 
      command :: String
    , path    :: FilePath
    , flags   :: [String]
    }

    deriving (Eq,Show)


data SearchSetting = SearchSetting {
      searchPaths    :: [FilePath]
    , applyedCommand :: Maybe Command
    , filters        :: FilterFlags
} deriving (Eq,Show)


-- | regxPattern. regexFilter 
-- | exclude liste med mapper du vil eksludere
-- | et falgg som lar deg spesifisere extention 
-- | om vil den skal søk igjennom hidden files
data FilterFlags = FilterFlags {
      regxPattern   :: Maybe SearchPattern
    , exclude       :: Maybe SearchFilters
    , extention     :: Maybe Extention
    , hideHidden    :: Bool

}  deriving (Eq, Show)


getRexPattern :: Maybe Regex -> RawFilePath -> Bool
getRexPattern Nothing      _  = True
getRexPattern (Just regex) fp = matchTest regex fp

-- Allow searchFilter
getDisallowFilter :: FilterFlags -> RawFilePath -> Bool
getDisallowFilter sf fp = maybe True (fp `notElem ` ) (exclude sf)  -- Blir True dersom fp ikke elem i 

-- Hvis du vil syntes det er lesbart 
-- getDisallowFilter = flip (maybe True . notElem) . exclude 

getHiddenFilter :: FilterFlags -> RawFilePath -> Bool
getHiddenFilter sf fp = not (hideHidden sf) || (BC.head fp /= '.')

getExtentionFilter :: FilterFlags -> RawFilePath ->  Bool
getExtentionFilter sf fp = case extention sf of
                        Nothing    ->  True
                        (Just ext) -> case getFileExtention fp of
                                        Nothing     -> False
                                        (Just curr) -> BC.tail curr == ext
-- helpers
getFileExtention :: Extention -> Maybe Extention
getFileExtention fp = if BS.null ext
                      then Nothing
                      else Just ext
                        where
                        ext = takeExtension fp

-- | compiles the regex pattern
compileRegexFilter :: FilterFlags -> Maybe Regex
compileRegexFilter sf =
  case regxPattern sf of
    Nothing  ->  Nothing
    Just pat ->  Just $ makeRegexOpts comp exec pat
  where
    comp = defaultCompOpt
    exec = defaultExecOpt { captureGroups = False }

generateCommand :: Command -> String
generateCommand = undefined 

convertString :: String -> RawFilePath
convertString = BC.pack

