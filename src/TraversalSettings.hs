{-# LANGUAGE ViewPatterns #-}
{-|

Module      : TraversalSettings
Description : Innstillinger og filtre for fil-/mappetraversering
License     : (ukjent)
Maintainer  : (ukjent)

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

import Text.Regex.TDFA
  ( Regex
  , ExecOption(..)
  , defaultCompOpt
  , defaultExecOpt
  , makeRegexOpts
  , matchTest
  )
import Data.ByteString (ByteString)

-- Datastruktur som holder filnavnet
-- type FolderState a = StateT FolderAndContent IO a
type Extention     = RawFilePath
type SearchPattern = RawFilePath
type SearchFilters = [RawFilePath]
type Command       = Maybe String



data SearchSetting = SearchSetting {
      searchPaths    :: Maybe [FilePath]
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


-- Hvis du vil:
-- getDisallowFilter = flip (maybe True . notElem) . exclude 
getHiddenFilter :: FilterFlags -> RawFilePath -> Bool
getHiddenFilter sf fp = not (hideHidden sf) || (BC.head fp /= '.')

getExtentionFilter :: FilterFlags -> RawFilePath -> Bool
getExtentionFilter (extention -> Nothing) _                                  = True
getExtentionFilter (extention -> (Just _)  ) (getFileExtention -> Nothing)   = False
getExtentionFilter (extention -> (Just ext)) (getFileExtention -> Just curr) = curr == ext


-- | compiles the regex pattern
compileRegexFilter :: FilterFlags -> Maybe Regex
compileRegexFilter (regxPattern  -> Nothing)    = Nothing
compileRegexFilter (regxPattern  -> (Just pat)) = Just $ makeRegexOpts comp exec pat
  where
    comp = defaultCompOpt
    exec = defaultExecOpt { captureGroups = False }

-- helpers
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



-- {-# DEPRECATED message #-}
getExtentionFilter_ :: FilterFlags -> RawFilePath -> Bool
getExtentionFilter_ sf fp = case extention sf of
                        Nothing    ->  True
                        (Just ext) -> case getFileExtention fp of
                                        Nothing     -> False
                                        (Just curr) ->  curr == ext
-- {-# DEPRECATED message #-}
compileRegexFilter_ :: FilterFlags -> Maybe Regex
compileRegexFilter_ sf =
  case regxPattern sf of
    Nothing  ->  Nothing
    Just pat ->  Just $ makeRegexOpts comp exec pat
  where
    comp = defaultCompOpt
    exec = defaultExecOpt { captureGroups = False }
