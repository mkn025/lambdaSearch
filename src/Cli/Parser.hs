module Cli.Parser (runParserIO, runMyParser, parseLamdaSearch) where


import Data.Void              (Void)
import Control.Applicative    ((<|>))
import Data.Functor           (($>))
import Text.Megaparsec.Char   (char, string, string')
import Control.Exception.Base (throwIO)
import Core.Filters           (convertString)


import Core.SettingsTypes    (
      SearchSetting     (..)
    , Arguments         (..)
    , Args              (..)
    , ProgramSettings   (..)
    , ConstrucedCommand
    )

import Text.Megaparsec (
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
import Core.PrintTypes (PrintSettings (matchColor, pathType, PrintSettings), OutputColor (Redish, Greeny, Blueish), PathType (AbsolutPathFilePath, RelativeFilePath))


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

defaultPrintSettings :: PrintSettings
defaultPrintSettings = PrintSettings{
      pathType    = RelativeFilePath
    , matchColor  = Greeny
    }

defaultSearchSetting :: SearchSetting
defaultSearchSetting = SearchSetting{
      searchPaths    = Nothing
    , arguments      = defaultArguments 
    }


defaultProgramSetting :: ProgramSettings
defaultProgramSetting = ProgramSettings {
      searchSetting  = defaultSearchSetting 
    , printSettings  = defaultPrintSettings 
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


data PrintFlags = 
      Color String
    | FullPath


data Flags = DataFlags DataFlags | PrintFlags PrintFlags


-- |  Parser for enkeltflagg og fmapper vår datatype på
pFlags :: Parser Flags
pFlags = choice
    [
       DataFlags  . SearchPatternFlag <$> ((string' "-p" <|> string  "--pattern"   ) *> sc *> parseWord)
     , DataFlags    HiddenFilesFlag   <$  ( string' "-a" <|> string  "--show--dots")
     , DataFlags  . ExtentionFlag     <$> ((string' "-e" <|> string  "--extention" ) *> sc *> (parseManyExteions <|> (singleton <$> parseWord) ))
     , DataFlags  . IgnoreFlag        <$> ((string' "-i" <|> string  "--ignore"    ) *> sc *> pathsUntilFlag )
     , DataFlags  . ExecuteFlag       <$> ((string' "-x" <|> string  "--execute"   ) *> sc *> parseConstrucedCommand) 
     , PrintFlags . Color             <$> ((string' "-c" <|> string  "--color"     ) *> sc *> parseWord) 
     , PrintFlags   FullPath          <$  (string' "-f" <|> string  "--full-path"  ) 
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



applyDataFlags :: Arguments -> DataFlags -> Arguments
applyDataFlags st (SearchPatternFlag s) = st {regxPattern    = Just (convertString s)}
applyDataFlags st (ExtentionFlag     e) = st {extention      = (convertString <$> e) <> extention st}
applyDataFlags st (IgnoreFlag        i) = st {exclude        = Just (map convertString i)}
applyDataFlags st (ExecuteFlag       x) = st {applyedCommand = Just x}
applyDataFlags st  HiddenFilesFlag      = st {hideHidden     = not . hideHidden $ st}


applyPrintSettings ::  PrintSettings -> PrintFlags -> PrintSettings
applyPrintSettings  ps (Color "red")   = ps {matchColor  = Redish}
applyPrintSettings  ps (Color "green") = ps {matchColor  = Greeny}
applyPrintSettings  ps (Color "blue")  = ps {matchColor  = Blueish}
applyPrintSettings  ps (Color _)       = ps
applyPrintSettings  ps FullPath        = ps {pathType  = AbsolutPathFilePath}


updateSearchSetting :: SearchSetting -> Arguments -> DataFlags -> SearchSetting
updateSearchSetting ss args df = ss {arguments  = applyDataFlags args df }




applyFlag :: ProgramSettings -> Flags -> ProgramSettings
applyFlag pgs@ProgramSettings{..} (DataFlags a)  = pgs { searchSetting  = updateSearchSetting searchSetting (arguments  searchSetting) a } 
applyFlag pgs@ProgramSettings{..} (PrintFlags a) = pgs { printSettings  = applyPrintSettings printSettings a  }  


-- | Parser mange dataflagg          =
parseAllFlags :: Parser [Flags]
parseAllFlags = many (sc *> pFlags <* sc) -- 


-- | Parser alle flagg og folder dem inn i én 'Arguments'-verdi.
--  Burker listen som av flagg som er parset og applyfalg og foldr over alle og lager Arguments datastukruen
parseFlags :: Parser ProgramSettings
parseFlags = foldl' applyFlag defaultProgramSetting <$> parseAllFlags


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
parseLamdaSearch :: Parser ProgramSettings
parseLamdaSearch = do
    paths <- sc *> parsePathOrDot
    prgs  <- parseFlags
    case paths of
        NoPath           -> pure prgs
        (ManyPaths [])   -> pure prgs
        (ManyPaths p)    -> pure $ applyPath prgs p 
    where 
        applyPath :: ProgramSettings -> [String] -> ProgramSettings 
        applyPath ps s = ps {searchSetting = SearchSetting{
              searchPaths = Just s
            , arguments  =  (arguments . searchSetting) ps 
            }}





-- | Lagde en et typealias bare for å gjøre det tydelig hva strengen skal brukes til
type StringToParse = String

-- | Kjører parser på en streng og generer feilmelding om den feiler
runMyParser :: Parser a -> StringToParse ->  Either String a
runMyParser parser input =
  case runParser parser "" input of
    Left err -> Left $ errorBundlePretty err
    Right x  -> Right x

-- | IO-wrapper som kaster feil dersom vi ikke klare å parse
runParserIO :: StringToParse -> IO ProgramSettings
runParserIO (runMyParser parseLamdaSearch -> (Right ss)) = pure ss
runParserIO (runMyParser parseLamdaSearch -> (Left er) ) = throwIO $ userError er




