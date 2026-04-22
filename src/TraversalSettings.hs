
module TraversalSettings (
      Arguments   (..)
    , SearchSetting (..)
    , getDisallowFilter
    , getHiddenFilter
    , getExtentionFilter
    , compileRegexFilter
    , getRexPattern
    , executeFunction
    , ConstrucedCommand
    , substituePath
    , convertString 
    , convertToString 
) where

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


-- | Type aliers for og øke lesbarheten
type Extention     = RawFilePath
type SearchPattern = RawFilePath
type SearchFilters = [RawFilePath]


-- | alias som beskriver en kommaddo eksterne kommandoer og argumenter.
type ConstrucedCommand = (String, [Command])

-- | datatype som blir brukt i  @--execute@. for å substite path
data Command = Text String | PathToSubs 
    deriving (Eq,Show)

-- | TODO: Dokumenter globale søkeinnstillinger.
data SearchSetting = SearchSetting {
      searchPaths    :: Maybe [FilePath]
    , arguments      :: Arguments
} deriving (Eq,Show)


-- | Søke- og filterargumenter for traversering.
-- Datatype som beskriver hvilke argumenter vi vi skal når vi treverser igjennom
--
-- - @regxPattern@: regex-filter.
-- - @exclude@: liste med mapper som skal ekskluderes.
-- - @extention@: valgfritt filter på filendelse.
-- - @hideHidden@: om skjulte filer skal vies.

data Arguments = Arguments {
      regxPattern    :: Maybe SearchPattern
    , exclude        :: Maybe SearchFilters
    , extention      :: Maybe Extention
    , hideHidden     :: Bool
    , applyedCommand :: Maybe ConstrucedCommand

}  deriving (Eq, Show)



-- | Mathcer fil med regex og 
-- | Tar med all dersom ikke noe spesifisert
getRexPattern :: Maybe Regex -> RawFilePath -> Bool
getRexPattern Nothing      _  = True
getRexPattern (Just regex) fp = matchTest regex fp


-- | Sjekker om filepath ikke er element i sitene vi har definert 
-- | Tar med all dersom ikke noe spesifisert
getDisallowFilter :: Arguments -> RawFilePath -> Bool
getDisallowFilter (exclude -> Nothing)  _ = True
getDisallowFilter (exclude -> Just sf) fp = fp `notElem ` sf


-- | Filterlogikk for skjulte filer.
-- | Sjekker om head til filen @.@
-- | Tar med alle dersom ikke noe spesifiser
getHiddenFilter :: Arguments -> RawFilePath -> Bool
getHiddenFilter (hideHidden  -> False) _ = True
getHiddenFilter (hideHidden  -> True) fp = BC.head fp /= '.'

-- | Filter som filterer for de rikgte extentionene 
-- | Tar med alle dersom ikke noe spesifiser
getExtentionFilter :: Arguments -> RawFilePath -> Bool
getExtentionFilter (extention -> Nothing) _                                = True
getExtentionFilter (extention -> Just _ )  (getFileExtention -> Nothing)   = False
getExtentionFilter (extention -> Just ext) (getFileExtention -> Just curr) = curr == ext


-- | Kompilerer regex-mønsteret. 
-- | Git nothing dersom brukeren ikke har spesifisert noe
compileRegexFilter :: Arguments -> Maybe Regex
compileRegexFilter (regxPattern  -> Nothing)    = Nothing
compileRegexFilter (regxPattern  -> (Just pat)) = Just $ makeRegexOpts comp exec pat
  where
    comp = defaultCompOpt
    exec = defaultExecOpt { captureGroups = False }


-- | litt mer fifi
-- | Bruker en funksjon f på på en RawFilePath dersom har sagt at vi skal exeute en kommando
executeFunction :: Arguments -> RawFilePath -> (ConstrucedCommand -> RawFilePath -> IO ())  -> IO ()
executeFunction (applyedCommand -> Nothing)  _  _ = pure ()
executeFunction (applyedCommand -> Just cmd) fp f = f cmd fp



-- | Bytter alle @{}@ med en git filepath
substituePath :: [Command] -> RawFilePath -> [String]
substituePath cmd rfp = map (inPathSubsitute rfp) cmd
    where 
        inPathSubsitute fp PathToSubs = convertToString fp
        inPathSubsitute _  (Text a)   = a



getFileExtention :: RawFilePath -> Maybe Extention
getFileExtention (BS.null -> True) = Nothing
getFileExtention  fp               = safeHead . takeExtension $ fp

safeHead :: ByteString -> Maybe ByteString
safeHead (BS.null -> True) = Nothing
safeHead xs                = Just $ BC.tail xs

convertString :: String -> RawFilePath
convertString = BC.pack

convertToString :: RawFilePath  -> String
convertToString = BC.unpack


