{- HLINT ignore "Use <$>" -}
{-# OPTIONS_GHC -Wno-unused-top-binds #-}



module ParseInput (runParserIO) where

import TraversalSettings    ( SearchSetting (..), Arguments (..), convertString, Command)
import Data.Void            (Void)
import Control.Applicative  ((<|>))
import Data.Functor         (($>))

import Text.Megaparsec.Char (char, string)

import Control.Exception.Base (throwIO)

import Text.Megaparsec      (
      Parsec
    , satisfy
    , between
    , parseTest
    , many
    , manyTill
    , eof
    , lookAhead
    , choice
    , skipMany
    , runParser )

import Data.List (foldl')
import Text.Megaparsec.Error (errorBundlePretty)

type Parser = Parsec Void String


tester :: IO ()
tester = do
    parseTest parseLamdaSearch ". -p test -e java -x cat {} > {} test.txt " 
    

sc :: Parser ()
sc = skipMany (char ' ' <|> char '\t')

parseUntilSpace :: Parser String
parseUntilSpace = many (satisfy (/=' '))

parseToCurlyBrackets :: Parser String
parseToCurlyBrackets = 
      string "{}"  
  <|> between (char '"') (char '"') (many (satisfy (/= '"')))
  <|> parseUntilSpace


emptyFilterFlags :: Arguments
emptyFilterFlags = Arguments {
      regxPattern    = Nothing
    , exclude        = Nothing
    , extention      = Nothing
    , hideHidden     = False
    , applyedCommand = Nothing
    }


data Paths =
      NoPath
    | ManyPaths [String]

data DataFlags =
      SearchPatternFlag String
    | HiddenFilesFlag
    | ExtentionFlag     String
    | ExecuteFlag      [String]
    | IgnoreFlag       [String]


pFlags :: Parser DataFlags
pFlags = choice
    [
       SearchPatternFlag <$> ((string "-p" <|> string  "--pattern"   ) *> sc *> parseUntilSpace)
     , HiddenFilesFlag   <$  ( string "-a" <|> string  "--show--dots")
     , ExtentionFlag     <$> ((string "-e" <|> string  "--extention" ) *> sc *> parseUntilSpace)
     , IgnoreFlag        <$> ((string "-i" <|> string  "--ignore"    ) *> sc *> pathsUntilFlag )
     , ExecuteFlag       <$> ((string "-x" <|> string  "--execute"   ) *> sc *> pCommadsAndArgs) --skipper forløpig
    ]

pCommadsAndArgs :: Parser Command -- [Strings]
pCommadsAndArgs = 
    manyTill
    (parseToCurlyBrackets <* sc )
    (lookAhead (pFlags $> () <|> eof)) -- end of file. fungere med null flagg også


applyFlag :: Arguments -> DataFlags -> Arguments
applyFlag st df = case df of
     SearchPatternFlag s -> st {regxPattern    = Just (convertString s)}
     ExtentionFlag     e -> st {extention      = Just (convertString  e)}
     IgnoreFlag        i -> st {exclude        = Just (map convertString i)}
     ExecuteFlag       x -> st {applyedCommand = Just x}
     HiddenFilesFlag     -> st {hideHidden     = True  } 

parseAllFlags :: Parser [DataFlags]
parseAllFlags = many (sc *> pFlags <* sc) -- 


-- Satan for en eleganse i dette. Hadde tenkt å bruke state monaden, men trenger ikke det
parseFlags :: Parser Arguments
parseFlags = do
  fs <- parseAllFlags --Løfter ut monaden
  pure (foldl' applyFlag emptyFilterFlags fs)  --foldr over

-- parser for stier
parsePath :: Parser String
parsePath = do
    slash      <- sc *> char '/'
    entirePath <- parseUntilSpace
    pure (slash : entirePath )

parsePathWithQuote :: Parser String
parsePathWithQuote = between (char '"') (char '"') (many (satisfy (/= '"')))


pathsUntilFlag :: Parser [String]
pathsUntilFlag =
  manyTill
    ((parsePath <|> parsePathWithQuote) <* sc)
    (lookAhead (pFlags $> () <|> eof)) -- end of file. fungere med null flagg også


parsePathOrDot :: Parser Paths
parsePathOrDot = choice
     [
          NoPath     <$ (sc *> char '.' <* sc )
        , ManyPaths  <$> pathsUntilFlag
     ]

-- Main parser
parseLamdaSearch :: Parser SearchSetting
parseLamdaSearch = do
    paths <- sc *> parsePathOrDot
    args  <- parseFlags
    let ss = SearchSetting {
           searchPaths  = Nothing
         , arguments    = args }

    case paths of
        NoPath           -> pure ss
        (ManyPaths [])   -> pure ss 
        (ManyPaths p)    -> pure ss {searchPaths = Just p} 


runMyParser :: Parser a -> String ->  Either String a
runMyParser parser input =
  case runParser parser "" input of
    Left err  -> Left $ errorBundlePretty err
    Right x   -> Right x


type StringToParse = String

runParserIO :: StringToParse -> IO SearchSetting
runParserIO (runMyParser parseLamdaSearch -> (Right ss)) = pure  ss
runParserIO (runMyParser parseLamdaSearch -> (Left er))  = throwIO $ userError er 

--{-# DEPRECATED message #-}
runParserIO_ :: StringToParse -> IO SearchSetting
runParserIO_ s = case runMyParser parseLamdaSearch s of
        Right ss -> pure ss
        Left  er -> throwIO (userError  er)




