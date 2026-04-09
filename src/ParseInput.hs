{-# LANGUAGE OverloadedStrings #-}
{-# OPTIONS_GHC -Wno-unused-do-bind #-}
{- HLINT ignore "Use <$>" -}

module ParseInput where

import TraversalSettings    ( SearchSetting (..), FilterFlags (..), convertString)
import Data.Void            (Void)
import Control.Applicative  ((<|>))
import Data.Functor         (($>))

import Text.Megaparsec.Char (char, string)
import Text.Megaparsec      (
      Parsec
    , satisfy
    , parseTest
    , between
    , many
    , manyTill
    , eof
    , lookAhead
    , choice, skipMany, runParser )

import Data.List (foldl')
 
type Parser = Parsec Void String

tester :: IO ()
tester = do 
    test <- getLine 
    parseTest parseLamdaSearch test 


-- Parser helper
parseSpace :: Parser Char
parseSpace = char ' '

parseLms :: Parser String
parseLms = string "lms "

sc :: Parser ()
sc = skipMany (char ' ' <|> char '\t')

parseUntilSpace :: Parser String 
parseUntilSpace = many (satisfy (/=' '))


emptyFilterFlags :: FilterFlags
emptyFilterFlags = FilterFlags {
      regxPattern = Nothing
    , exclude     = Nothing
    , extention   = Nothing
    , hideHidden  = False
    } 


data DataFlags = 
      SearchPatternFlag String
    | HiddenFilesFlag
    | ExtentionFlag     String
    | IgnoreFlag        [String]
    | ExecuteFlag       String


pFlags :: Parser DataFlags
pFlags = choice
    [
       SearchPatternFlag <$> ((string "-p" <|> string  "--pattern"   ) *> sc *> parseUntilSpace)
     , HiddenFilesFlag   <$  ( string "-a" <|> string  "--show--dots")
     , ExtentionFlag     <$> ((string "-e" <|> string  "--extention" ) *> sc *> parseUntilSpace)
     , IgnoreFlag        <$> ((string "-i" <|> string  "--ignore"    ) *> sc *> pathsUntilFlag )
     , ExecuteFlag       <$> ((string "-x" <|> string  "--execute"   ) *> sc *> parseUntilSpace) --skipper forløpig
    ]

applyFlag :: FilterFlags -> DataFlags -> FilterFlags
applyFlag st df = case df of
     SearchPatternFlag s -> st {regxPattern = Just (convertString s)}
     ExtentionFlag     e -> st {extention   = Just (convertString  e)}
     IgnoreFlag        i -> st {exclude     = Just (map convertString i)}
     HiddenFilesFlag     -> st {hideHidden  = True}
     ExecuteFlag       _ -> st

parseAllFlags :: Parser [DataFlags]
parseAllFlags = many (sc *> pFlags <* sc)


-- Satan for en eleganse i dette. Hadde tenkt å bruke state monaden, men trenger ikke det
parseFlags :: Parser FilterFlags
parseFlags = do
  fs <- parseAllFlags --Løfter ut monaden
  pure (foldl' applyFlag emptyFilterFlags fs)  --foldr over

-- parser for stier
parsePath :: Parser String
parsePath = between (char '"') (char '"') (many (satisfy (/= '"')))

pathsUntilFlag :: Parser [String]
pathsUntilFlag =
  manyTill
    (parsePath <* sc)
    (lookAhead (pFlags $> () <|> eof))



-- Main parser
parseLamdaSearch :: Parser SearchSetting
parseLamdaSearch = do 
    sc *> parseLms  
    paths <- pathsUntilFlag
    flags <- parseFlags 
    pure $ SearchSetting 
        { 
           searchPaths    = paths
         , applyedCommand = Nothing
         , filters        = flags
        }


runMyParser :: Parser a -> String ->  Maybe a
runMyParser parser input =
  case runParser parser "" input of
    Left _  -> Nothing
    Right x -> Just x



