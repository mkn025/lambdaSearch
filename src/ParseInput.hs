{-# LANGUAGE OverloadedStrings #-}
{-# OPTIONS_GHC -Wno-unused-do-bind #-}

module ParseInput where
import Text.Megaparsec      (Parsec, satisfy, parseTest, between,many,sepEndBy )
import Text.Megaparsec.Char (char, string, hspace1 )
import Data.Void            (Void)

import TraversalSettings ( SearchSetting (..), FilterFlags (..))
 
type Parser = Parsec Void String

tester :: IO ()
tester = do 
    test <- getLine 
    parseTest parseLamdaSearch test 

parseSpace :: Parser Char
parseSpace = char ' '

parseLms :: Parser String
parseLms = string "lms "

parsePath :: Parser String
parsePath = between (char '"') (char '"') (many (satisfy (/= '"')))

parseManyPath :: Parser [String]
parseManyPath = parsePath `sepEndBy` hspace1 

parseFilters :: Parser FilterFlags
parseFilters = undefined 

parseLamdaSearch :: Parser SearchSetting
parseLamdaSearch = do 
    parseLms 
    paths <- parseManyPath 
    parseSpace 
    pure $ SearchSetting {
          searchPaths    = paths
        , applyedCommand = Nothing
        , filters        = Nothing
        }
    

    



