{-|

Module      : TraversalSettings
Description : Innstillinger og filtre for fil-/mappetraversering

Denne modulen definerer:
* 'SearchSetting' – overordnede søkeinnstillinger (stier, kommando, filterflagg)
* 'FilterFlags'   – filtre som kan begrense hvilke filer som skal vurderes
* Hjelpefunksjoner for å kompilere regex og for å sjekke skjulte filer/filendelser

Typene bruker 'RawFilePath' (ByteString-basert) fra @unix@-økosystemet.

-}

module TraversalSettings where

import System.Posix.ByteString               (RawFilePath)
import qualified Data.ByteString.Char8 as BC (head,pack,unpack,tail)
import qualified Data.ByteString as BS       (null)
import System.FilePath.ByteString            (takeExtension)
import Data.ByteString                       (ByteString)

import Text.Regex.TDFA(
    Regex
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
type ConstrucedCommand = (String, [Command])

data Command = Text String | PathToSubs 
    deriving (Eq,Show)

data SearchSetting = SearchSetting {
      searchPaths    :: Maybe [FilePath]
    , arguments      :: Arguments
} deriving (Eq,Show)

-- | regxPattern. regexFilter 
-- | exclude liste med mapper du vil eksludere
-- | et falgg som lar deg spesifisere extention 
-- | om vil den skal søk igjennom hidden files

data Arguments = Arguments {
      regxPattern    :: Maybe SearchPattern
    , exclude        :: Maybe SearchFilters
    , extention      :: Maybe Extention
    , hideHidden     :: Bool
    , applyedCommand :: Maybe ConstrucedCommand

}  deriving (Eq, Show)


defaultFlags :: Arguments
defaultFlags = Arguments {
    regxPattern    = Nothing
  , exclude        = Nothing
  , extention      = Nothing
  , hideHidden     = True
  , applyedCommand = Nothing
}

dss :: SearchSetting
dss = SearchSetting {
      searchPaths    =  Nothing
    , arguments      =  defaultFlags 
}

getRexPattern :: Maybe Regex -> RawFilePath -> Bool
getRexPattern Nothing      _  = True
getRexPattern (Just regex) fp = matchTest regex fp

-- Allow searchFilter
getDisallowFilter :: Arguments -> RawFilePath -> Bool
getDisallowFilter (exclude -> Nothing)  _ = True
getDisallowFilter (exclude -> Just sf) fp = fp `notElem ` sf


getHiddenFilter :: Arguments -> RawFilePath -> Bool
getHiddenFilter (hideHidden  -> False) _ = True
getHiddenFilter (hideHidden  -> True) fp = BC.head fp /= '.'

getExtentionFilter :: Arguments -> RawFilePath -> Bool
getExtentionFilter (extention -> Nothing) _                                = True
getExtentionFilter (extention -> Just _ )  (getFileExtention -> Nothing)   = False
getExtentionFilter (extention -> Just ext) (getFileExtention -> Just curr) = curr == ext


-- | compiles the regex pattern
compileRegexFilter :: Arguments -> Maybe Regex
compileRegexFilter (regxPattern  -> Nothing)    = Nothing
compileRegexFilter (regxPattern  -> (Just pat)) = Just $ makeRegexOpts comp exec pat
  where
    comp = defaultCompOpt
    exec = defaultExecOpt { captureGroups = False }

executeFunction :: Arguments -> RawFilePath -> (ConstrucedCommand -> RawFilePath -> IO ())  -> IO ()
executeFunction (applyedCommand -> Nothing)  _  _ = pure ()
executeFunction (applyedCommand -> Just cmd) fp f = f cmd fp


-- helpers
substituePath :: [Command] -> RawFilePath -> [String]
substituePath cmd rfp = map (inPathSubsitute rfp) cmd
    where 
        inPathSubsitute fp PathToSubs = convertToString fp
        inPathSubsitute _  (Text a)   = a


getFileExtention :: RawFilePath -> Maybe Extention
getFileExtention (BS.null -> True) = Nothing
getFileExtention  fp               = safeHead . takeExtension $ fp

safeHead :: ByteString -> Maybe ByteString
safeHead (BS.null -> True)  = Nothing
safeHead xs                 = Just $ BC.tail xs

convertString :: String -> RawFilePath
convertString = BC.pack

convertToString :: RawFilePath  -> String
convertToString = BC.unpack



