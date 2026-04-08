{-# LANGUAGE OverloadedStrings #-}
{-# OPTIONS_GHC -Wno-unused-do-bind #-}

module ParseInput where


import TraversalSettings    ( SearchSetting (..), FilterFlags (..))

import Data.Void            (Void)
import Control.Applicative  ((<|>))
import Data.Functor         (($>))

import Text.Megaparsec.Char (char, string, hspace1 )
import Text.Megaparsec (
      Parsec
    , satisfy
    , parseTest
    , between
    , many
    , manyTill
    , eof
    , lookAhead
    , choice )
 
type Parser = Parsec Void String

tester :: IO ()
tester = do 
    test <- getLine 
    parseTest parseLamdaSearch test 

parseSpace :: Parser Char
parseSpace = char ' '

parseLms :: Parser String
parseLms = string "lms "

data DataFlags = 
      SearchPatternFlag 
    | HiddenFilesFlag
    | ExtentionFlag
    | IgnoreFlag
    | ExecuteFlag


pFlags :: Parser DataFlags
pFlags = choice
    [  SearchPatternFlag <$ string "-p"
     , HiddenFilesFlag   <$ string "-a"
     , ExtentionFlag     <$ string "-e"
     , IgnoreFlag        <$ string "-i"
     , ExecuteFlag        <$ string "-i"
    ]

parsePath :: Parser String
parsePath = between (char '"') (char '"') (many (satisfy (/= '"')))

pathsUntilFlag :: Parser [String]
pathsUntilFlag =
  manyTill
    (parsePath <* many (char ' ') )
    (lookAhead (pFlags $> () <|> eof))




parseLamdaSearch :: Parser SearchSetting
parseLamdaSearch = do 
    parseLms 
    paths <- pathsUntilFlag 

    pure $ SearchSetting {
          searchPaths    = paths
        , applyedCommand = Nothing
        , filters        = Nothing
        }
    

    



