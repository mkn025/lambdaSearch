module Core.SettingsTypes (
      Extention
    , SearchPattern
    , SearchFilters
    , ConstrucedCommand
    , Args             (..)
    , SearchSetting    (..)
    , Arguments        (..)
    , ProgramSettings  (..)
    , defaultArguments 
    )
    where

import Core.PrintTypes (PrintSettings (..),PathType (..),OutputColor (..))


import System.Posix.ByteString.FilePath (RawFilePath)

type Extention     = RawFilePath
type SearchPattern = RawFilePath
type SearchFilters = [RawFilePath]

-- | datatype som blir brukt i  @--execute@. for å substite path
data Args = Text String | PathToSubs
    deriving (Eq,Show)

-- | Alias som beskriver en kommaddo eksterne kommandoer og argumenter.
type ConstrucedCommand = (String, [Args])

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
    , extention      :: [Extention] 
    , hideHidden     :: Bool 
    , applyedCommand :: Maybe ConstrucedCommand
}  deriving (Eq, Show)

--  instillinger den skal søke etter
data SearchSetting = SearchSetting {
      searchPaths    :: Maybe [FilePath]
    , arguments      :: Arguments
} deriving (Eq,Show)



data ProgramSettings = ProgramSettings {
      searchSetting :: SearchSetting
    , printSettings :: PrintSettings 
    } deriving (Eq, Show)
    





defaultArguments :: Arguments
defaultArguments = Arguments {
      regxPattern    = Nothing
    , exclude        = Nothing
    , extention      = []
    , hideHidden     = False
    , applyedCommand = Nothing
    }




    -- 
    -- OutputColor,
    -- PathType,
    -- PrintSettings,
    -- 
    -- DirType,
    -- DirContent,
    -- FilePaths,
    -- FileInfomation,
    -- 
    -- defaultArguments
    -- NOTHING but data/newtype decls + trivial instances

