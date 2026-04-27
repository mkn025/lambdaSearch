module Main (main) where
import TreverselSettingsTest(mainTreverselSettingsTest)
import TraverselFunctionsTest (mainTraverselFunctionsTest)
import Test.Tasty (defaultMain, testGroup)

main :: IO ()
main = defaultMain $ testGroup 
    "Running all tests" $
       mainTreverselSettingsTest 
    <> mainTraverselFunctionsTest
     


