{- HLINT ignore "Use /=" -}
module FileTreversal where

import System.Posix.ByteString (RawFilePath)
import System.Posix.Files.ByteString (isRegularFile, getFileStatus)
import qualified Data.ByteString.Char8 as BC (head,pack, null, dropWhile, tail, takeWhile, reverse )
import GHC.Conc (BlockReason(BlockedOnMVar))

-- Datastruktur som holder filnavnet

--type FolderState a = StateT FolderAndContent IO a

type SearchFilters = [RawFilePath]
type Extention = RawFilePath

convertString :: String -> RawFilePath
convertString = BC.pack

data SearchSetting = SearchSetting {
      query         :: Maybe String        -- name/pattern to match
    , searchPaths   :: [RawFilePath]       -- [] = current directory
    , maxDepth      :: Maybe Int           -- Nothing = unlimited
    , filtes        :: FilterFlags
    }


data FilterFlags = FilterFlags {
      include       :: Maybe SearchFilters       -- allowlist globs
    , exclude       :: Maybe SearchFilters       -- denylist globs
    , extention     :: Maybe Extention       -- denylist globs
    , hidden        :: Bool                -- skal søke igjennom dotFiles
    , fileOnly      :: Bool                -- only regular files

  }  deriving (Eq, Show)


-- Allow searchFilter
getAllowFilter :: FilterFlags -> RawFilePath -> IO Bool -- de som er allowd er true
getAllowFilter sf fp = case include sf of
                       Nothing  -> pure True           -- da går alt med
                       (Just a) -> pure $  fp `elem` a -- 



getDisallowFilter :: FilterFlags -> RawFilePath -> IO Bool 
getDisallowFilter sf fp = case exclude sf of
                          Nothing  -> pure True              -- da går alt med
                          (Just a) -> pure $  fp `notElem` a -- da går den bare med om den ikke er element


getHiddenFilter :: FilterFlags -> RawFilePath -> IO Bool
getHiddenFilter sf fp = if hidden sf
                        then pure $ not $ BC.head fp == '.' -- vår en parser error når eg bruker !=
                        else pure True


getFileOnlyFilter :: FilterFlags -> RawFilePath -> IO Bool
getFileOnlyFilter sf fp = if fileOnly sf 
                          then isRegularFile <$> getFileStatus  fp -- om ikke kan den gjøre filter -- om ikke kan den gjøre filter
                          else pure True -- om den ikke skal sjekke etter bare filer, da skal alt med

getExtentionFilter :: FilterFlags -> RawFilePath -> IO Bool
getExtentionFilter sf fp = case extention sf of
                        Nothing    -> pure True 
                        (Just ext) -> case getFileExtention fp of
                                        Nothing     -> pure False 
                                        (Just curr) -> do 
                                            pure $ BC.tail curr == ext


getFileExtention :: RawFilePath -> Maybe RawFilePath
getFileExtention fp = if BC.null lst 
                      then Nothing
                      else Just lst
                        where
                        lst = BC.dropWhile  (not . (== '.')) fp








