module Core.Filters (
      getRexPattern
    , getDisallowFilter
    , getHiddenFilter 
    , getExtentionFilter 
    , compileRegexFilter 
    , executeFunction 
    , substituePath 
    , getFileExtention 
    , safeTail
    , safeHead 
    , convertString 
    , convertToString 
    ) where

import Core.SettingsTypes (
       Args(..)
     , Arguments (..)
     , ConstrucedCommand
     , Extention 
    )


import System.Posix.ByteString               (RawFilePath)
import qualified Data.ByteString.Char8 as BC (head, pack, unpack, tail, null, isPrefixOf)
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



getRexPattern :: Maybe Regex -> RawFilePath -> Bool
getRexPattern Nothing      _  = True
getRexPattern (Just regex) fp = matchTest regex fp

-- | Sjekker om filepath ikke er element i sitene vi har definert 
--  Tar med all dersom ikke noe spesifisert
getDisallowFilter :: Arguments -> RawFilePath -> Bool
getDisallowFilter (exclude -> Nothing)  _ = True
getDisallowFilter (exclude -> Just sf) fp = not $ any (`BC.isPrefixOf` fp) sf



-- | Filterlogikk for skjulte filer.
--  Sjekker om head til filen @.@
--  Tar med alle dersom ikke noe spesifiser
getHiddenFilter :: Arguments -> RawFilePath -> Bool
getHiddenFilter (hideHidden  -> False) _                    = True
getHiddenFilter (hideHidden  -> True) (safeHead -> Nothing) = True
getHiddenFilter (hideHidden  -> True) (safeHead -> Just h)  = h /= '.'


-- | Filter som filterer for de rikgte extentionene 
--  Tar med alle dersom ikke noe spesifiser
getExtentionFilter :: Arguments -> RawFilePath -> Bool
getExtentionFilter (extention -> [] ) _                               = True
getExtentionFilter (extention ->  _ ) (getFileExtention -> Nothing)   = False
getExtentionFilter (extention -> ext) (getFileExtention -> Just curr) = curr `elem` ext


-- | Kompilerer regex-mønsteret. 
--  Git nothing dersom brukeren ikke har spesifisert noe
compileRegexFilter :: Arguments -> Maybe Regex
compileRegexFilter (regxPattern  -> Nothing)    = Nothing
compileRegexFilter (regxPattern  -> (Just pat)) = Just $ makeRegexOpts comp exec pat
  where
    comp = defaultCompOpt
    exec = defaultExecOpt { captureGroups = False }



-- | Litt mer fifi
--  Bruker en funksjon f på på en RawFilePath dersom har sagt at vi skal exeute en kommando
--  Generaliserer bare den slik at vi ikke trenger og importere masse BS (ikke byteString) i denne modulen

executeFunction ::
    Arguments                                   ->
    RawFilePath                                 ->
    (ConstrucedCommand -> RawFilePath -> IO ()) -> 
    IO ()
executeFunction (applyedCommand -> Nothing)  _  _ = pure ()
executeFunction (applyedCommand -> Just cmd) fp f = f cmd fp


-- | Bytter alle @{}@ med en git filepath
substituePath :: [Args] -> RawFilePath -> [String]
substituePath cmd rfp =  inPathSubsitute rfp <$> cmd
    where
        inPathSubsitute fp PathToSubs = convertToString fp
        inPathSubsitute _  (Text a)   = a


getFileExtention :: RawFilePath -> Maybe Extention
getFileExtention (BC.null -> True) = Nothing
getFileExtention  fp               = safeTail . takeExtension $ fp

safeTail :: ByteString -> Maybe ByteString
safeTail (BC.null -> True) = Nothing
safeTail xs                = Just . BC.tail  $ xs

safeHead :: ByteString -> Maybe Char
safeHead (BC.null -> True) = Nothing
safeHead xs                = Just . BC.head $ xs

convertString :: String -> RawFilePath
convertString = BC.pack

convertToString :: RawFilePath  -> String
convertToString = BC.unpack



