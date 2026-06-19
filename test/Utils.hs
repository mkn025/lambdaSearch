
module Utils where

import qualified Data.ByteString.Char8 as BC
import Test.Tasty.QuickCheck (Arbitrary(arbitrary), listOf, suchThat )
import Data.Char             (isAscii)
import TraversalSettings     (Arguments (..), SearchSetting (..))



newtype AsciiString = AsciiString String deriving Show

instance Arbitrary AsciiString where
  arbitrary = AsciiString <$> listOf (arbitrary `suchThat` isAscii)

bs :: String -> BC.ByteString
bs = BC.pack



defaultArgs :: Arguments
defaultArgs = Arguments
    { regxPattern    = Nothing
    , exclude        = Nothing
    , extention      = []
    , hideHidden     = False
    , applyedCommand = Nothing
    }


defaultSettings :: [FilePath] -> SearchSetting
defaultSettings paths = SearchSetting
    { searchPaths = Just paths
    , arguments   = defaultArgs
    }
