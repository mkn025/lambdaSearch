{- HLINT ignore "Redundant if" -}
{- HLINT ignore "Use if" -}

module FileTraversal where

import System.Posix.ByteString (RawFilePath)
import qualified Data.ByteString.Char8 as BC (head,pack,tail)
import qualified Data.ByteString as BS (null)
import System.FilePath.ByteString (takeExtension)

import Text.Regex.TDFA
  ( Regex, CompOption(..), ExecOption(..)
  , defaultCompOpt, defaultExecOpt, makeRegexOpts
  , matchTest
  )

-- Datastruktur som holder filnavnet

--type FolderState a = StateT FolderAndContent IO a

type SearchFilters = [RawFilePath]

type Extention     = RawFilePath

type SearchPattern = String


convertString :: String -> RawFilePath
convertString = BC.pack

data SearchSetting = SearchSetting {
      searchPaths   :: [RawFilePath]
    , maxDepth      :: Maybe Int
    , filtes        :: FilterFlags

    }


data FilterFlags = FilterFlags {
      regxPattern   :: Maybe SearchPattern
    , include       :: Maybe SearchFilters       -- allowlist globs
    , exclude       :: Maybe SearchFilters       -- denylist globs
    , extention     :: Maybe Extention       -- searchFor Spe 
    , hideHidden    :: Bool                -- skal søke igjennom dotFiles

  }  deriving (Eq, Show)





-- Fast per-file check
getRexPattern :: Maybe Regex -> RawFilePath -> Bool
getRexPattern Nothing      _  = True
getRexPattern (Just regex) fp = matchTest regex fp


-- Allow searchFilter
getAllowFilter :: FilterFlags -> RawFilePath -> Bool
getAllowFilter sf fp = case include sf of
                       Nothing  -> True           -- da går alt med
                       (Just a) -> fp `elem` a

getDisallowFilter :: FilterFlags -> RawFilePath -> Bool
getDisallowFilter sf fp = case exclude sf of
                          Nothing  -> True              -- da går alt med
                          (Just a) -> fp `notElem` a -- da går den bare med om den ikke er element

getHiddenFilter :: FilterFlags -> RawFilePath -> Bool
getHiddenFilter sf fp = case hideHidden sf of 
                        True  -> BC.head fp /= '.' -- får en parser error når eg bruker 
                        False -> True

getExtentionFilter :: FilterFlags -> RawFilePath ->  Bool
getExtentionFilter sf fp = case extention sf of
                        Nothing    ->  True
                        (Just ext) -> case getFileExtention fp of
                                        Nothing     -> False
                                        (Just curr) -> BC.tail curr == ext




getFileExtention :: Extention -> Maybe Extention
getFileExtention fp = if BS.null ext
                      then Nothing
                      else Just ext
                        where
                        ext = takeExtension fp


-- | compiles the regex pattrerne

compileRegexFilter :: FilterFlags -> Maybe Regex 
compileRegexFilter sf =
  case regxPattern sf of
    Nothing  ->  Nothing
    Just pat ->  Just $ makeRegexOpts comp exec (BC.pack pat)
  where
    comp = defaultCompOpt
    exec = defaultExecOpt { captureGroups = False } -- faster if you only need Bool


