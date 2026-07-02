module ParseInput (runParserIO, runMyParser, parseLamdaSearch) where

import Data.Void            (Void)
import Control.Applicative  ((<|>))
import Data.Functor         (($>))

import Text.Megaparsec.Char (char, string, string')

import Control.Exception.Base (throwIO)

import TraversalSettings    (
      SearchSetting (..)
    , Arguments     (..)
    , Args          (..)
    , convertString
    , ConstrucedCommand
    )

import Text.Megaparsec      (
      Parsec
    , satisfy
    , between
    , many
    , manyTill
    , eof
    , lookAhead
    , choice
    , skipMany
    , runParser
    )

import Text.Megaparsec.Error (errorBundlePretty)
import Data.List             (foldl', singleton)

type Parser = Parsec Void String

-- Helper funksjoner

-- | Parser til whitespace-parseren. 
sc :: Parser ()
sc = skipMany (char ' ' <|> char '\t')


-- | Parser for ett  ord.
parseWord :: Parser String
parseWord = many (satisfy (\c -> c /= ' ' && c /= '\t'))


-- Parser til et et nytt flag 
parseToFlagsWithParser :: Parser a -> Parser [a]
parseToFlagsWithParser p =
  manyTill p (lookAhead (pFlags $> () <|> eof)) -- end of file. fungere med null flagg også



-- |  standardverdier for filterflagg.
defaultArguments :: Arguments
defaultArguments = Arguments {
      regxPattern    = Nothing
    , exclude        = Nothing
    , extention      = []
    , hideHidden     = False
    , applyedCommand = Nothing
    }

-- |  Representasjon av om søkestier er oppgitt.
data Paths =
      NoPath
    | ManyPaths [String]


-- | Datatype for å beskrive hvilken type informasjon vi kan parse
data DataFlags =
      SearchPatternFlag String
    | HiddenFilesFlag
    | ExtentionFlag     [String]
    | ExecuteFlag      ConstrucedCommand
    | IgnoreFlag       [String]


-- |  Parser for enkeltflagg og fmapper vår datatype på
pFlags :: Parser DataFlags
pFlags = choice
    [
       SearchPatternFlag <$> ((string' "-p" <|> string  "--pattern"   ) *> sc *> parseWord)
     , HiddenFilesFlag   <$  ( string' "-a" <|> string  "--show--dots")
     , ExtentionFlag     <$> ((string' "-e" <|> string  "--extention" ) *> sc *> (parseManyExteions <|> (singleton <$> parseWord) ))
     , IgnoreFlag        <$> ((string' "-i" <|> string  "--ignore"    ) *> sc *> pathsUntilFlag )
     , ExecuteFlag       <$> ((string' "-x" <|> string  "--execute"   ) *> sc *> parseConstrucedCommand) 
    ]




parseManyExteions :: Parser [String]
parseManyExteions =  parseToFlagsWithParser $ parseWord <* sc


-- | Parser våres argrumenter @Brukes med execute falgget@
--  Parser for ConstrucedCommand datatypen
parseConstrucedCommand :: Parser ConstrucedCommand
parseConstrucedCommand  = do
    cmd <- sc *> parseWord
    args <- parseManyArgs
    pure (cmd, args)


-- | Dokumenter parser for mange execute-argumenter frem til neste flagg.
parseManyArgs :: Parser [Args]
parseManyArgs = parseToFlagsWithParser $ sc *> parseArgs


-- | Parser for commando datatypen kan enten være en commando eller en sti
parseArgs :: Parser Args
parseArgs = do
        s <- sc *> (parseArgumentAndWord <|> parseWord) <* sc
        if s == "{}"
        then pure PathToSubs
        else pure $ Text s

-- | Parser argumener som starter med @-@ og tilhørende verdi.
--  Brukes bare til parse commandoeen
parseArgumentAndWord :: Parser String
parseArgumentAndWord = do
    f <- char '-'
    w <- parseWord <* sc
    s <- parseWord 
    pure (f : w <> s)


--- FLAG PARSER --- 

-- | Tar argument datatypen og  og et flag og putter det i datastukruen våre
--  Blir nesten som og oppdaterte en state
applyFlag :: Arguments -> DataFlags -> Arguments
applyFlag st df = case df of
     SearchPatternFlag s -> st {regxPattern    = Just (convertString s)}
     ExtentionFlag     e -> st {extention      = (convertString <$> e) <> extention st}
     IgnoreFlag        i -> st {exclude        = Just (map convertString i)}
     ExecuteFlag       x -> st {applyedCommand = Just x}
     HiddenFilesFlag     -> st {hideHidden     = not . hideHidden $ st}


-- | Parser mange dataflagg 
parseAllFlags :: Parser [DataFlags]
parseAllFlags = many (sc *> pFlags <* sc) -- 


-- | Parser alle flagg og folder dem inn i én 'Arguments'-verdi.
--  Burker listen som av flagg som er parset og applyfalg og foldr over alle og lager Arguments datastukruen
parseFlags :: Parser Arguments
parseFlags = foldl' applyFlag defaultArguments <$>parseAllFlags


--- STI PARSER ---

-- |  Parser for absolutt sti uten anførselstegn.
parsePath :: Parser String
parsePath = do
    slash      <- sc *> char '/'
    entirePath <- parseWord
    pure (slash : entirePath )

-- | Parser for sti omgitt av anførselstegn.
parsePathWithQuote :: Parser String
parsePathWithQuote = between (char '"') (char '"') (many (satisfy (/= '"')))

-- | Parser mange stier helt til vi kommer til et flag e
pathsUntilFlag :: Parser [String]
pathsUntilFlag = parseToFlagsWithParser $ (parsePath <|> parsePathWithQuote) <* sc

-- |  Parse første del av input. skal enten parse et punktum eller til flaggene begnner
parsePathOrDot :: Parser Paths
parsePathOrDot = choice
     [
          NoPath     <$ (sc *> char '.' <* sc )
        , ManyPaths  <$> pathsUntilFlag
     ]


--- HOVEDPARSER ---

-- | Parser hele input og generer en searchSetting datatype
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


-- | Lagde en et typealias bare for å gjøre det tydelig hva strengen skal brukes til
type StringToParse = String


-- | Kjører parser på en streng og generer feilmelding om den feiler
runMyParser :: Parser a -> StringToParse ->  Either String a
runMyParser parser input =
  case runParser parser "" input of
    Left err -> Left $ errorBundlePretty err
    Right x  -> Right x


-- | IO-wrapper som kaster feil dersom vi ikke klare å parse
runParserIO :: StringToParse -> IO SearchSetting
runParserIO (runMyParser parseLamdaSearch -> (Right ss)) = pure  ss
runParserIO (runMyParser parseLamdaSearch -> (Left er) ) = throwIO $ userError er




