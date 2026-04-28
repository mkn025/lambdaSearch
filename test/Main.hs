module Main (main) where

import TreverselSettingsTest  (mainTreverselSettingsTest)
import TraverselFunctionsTest (mainTraverselFunctionsTest)
import ParserTest (parserTests )


import Test.Tasty             (defaultMain, testGroup)


main :: IO ()
main = defaultMain $ testGroup 
    "Running all tests"
     [
       parserTests
     , mainTraverselFunctionsTest
     , mainTreverselSettingsTest 
     ]
     


