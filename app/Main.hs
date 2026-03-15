module Main where

import TreveseFunctions (treverFilePath, eqReg)
import FileTreversal


newtype PrettyList a = PrettyList [a]

instance Show a => Show (PrettyList a) where
  show (PrettyList xs) =
    "[\n" ++ unlines (map (\x -> "  " ++ show x) xs) ++ "]"

main :: IO ()
main = do
    pa <- getLine
    lst <- treverFilePath pa defaultFlags2
    let lst2 = map snd . filter (eqReg  . fst)
    newLst <- pure $ lst2 lst
    print $ PrettyList newLst 


defaultFlags2 :: FilterFlags
defaultFlags2 = FilterFlags {
    include     = Nothing
  , exclude     = Nothing
  , extention   = Just  $ convertString "java"
  , hideHidden  = False
  }

-- testA =  treverFilePath "/Users/martineldeknutsen/" defaultFlags2

 --testB a =  map snd . filter (eqReg  . fst) <$> a
 --
 --testC = PrettyList <$> testB




