module Main where

import TraverselsFunctions (treverFilePath)
import FileTraversal
import PrintFunctions

newtype PrettyList a = PrettyList [a]

instance Show a => Show (PrettyList a) where
  show (PrettyList xs) =
    "[\n" ++ unlines (map (\x -> "  " ++ show x) xs) ++ "]"



path = "/Users/martineldeknutsen/Dev/UiB/inf221/semesterProjekt/testMappe"

main :: IO ()
main = do
    lst <- treverFilePath path defaultFlags2
    printResults lst

    
    






defaultFlags2 :: FilterFlags
defaultFlags2 = FilterFlags {
    include     = Nothing
  , exclude     = Nothing
  , extention   = Just  $ convertString "java" , hideHidden  = False
  }

-- testA =  treverFilePath "/Users/martineldeknutsen/" defaultFlags2

 --testB a =  map snd . filter (eqReg  . fst) <$> a
 --
 --testC = PrettyList <$> testB




