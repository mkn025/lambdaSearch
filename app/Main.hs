module Main where

import TreveseFunctions (testA) 


path = "/Users/martineldeknutsen/Dev"

main :: IO ()
main = do
    a <- printLast <$> testA path 
    print a

printLast :: [a] -> a
printLast [x] = x
printLast (_:xs) = printLast xs




