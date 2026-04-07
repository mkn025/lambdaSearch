
{-# LANGUAGE OverloadedStrings #-}
module ParseInput where
import Text.Megaparsec     (Parsec, satisfy, parseTest,)
import Text.Megaparsec.Char(char, newline,string )
import Data.Void (Void)


type Parser = Parsec Void String

tester :: IO ()
tester = parseTest parseChar  "a"

parseChar :: Parser Char
parseChar = char 'a'

parseStart :: Parser String
parseStart = string "lms"

parseLamdaSearch :: Parser String
parseLamdaSearch = do 
    a <- string "lms"



