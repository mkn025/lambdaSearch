
module TraverselFunctionsTest (mainTraverselFunctionsTest)  where

import Test.Tasty
import Test.Tasty.HUnit
import Test.Tasty.QuickCheck

import System.IO.Temp                        (withSystemTempDirectory)
import System.Directory                      (createDirectory, createDirectoryIfMissing)
import System.Posix.Directory.Foreign        (dtReg)
import qualified Data.ByteString.Char8 as BC

import TraverselsFunctions
import TraversalSettings
import Data.Char (isAscii)

mainTraverselFunctionsTest :: [TestTree]
mainTraverselFunctionsTest = [testsConstructFilePath, testsTraversal]   


newtype AsciiString = AsciiString String deriving Show

instance Arbitrary AsciiString where
  arbitrary = AsciiString <$> listOf (arbitrary `suchThat` isAscii )


bs :: String -> BC.ByteString
bs = BC.pack

defaultArgs :: Arguments
defaultArgs = Arguments
    { regxPattern    = Nothing
    , exclude        = Nothing
    , extention      = Nothing
    , hideHidden     = False
    , applyedCommand = Nothing
    }

defaultSettings :: [FilePath] -> SearchSetting
defaultSettings paths = SearchSetting
    { searchPaths = Just paths
    , arguments   = defaultArgs
    }

-- lager en feilinformasjonhjelepr
mkFileInfo :: FilePath -> String -> FileInfomation
mkFileInfo parent name = FileInfomation
    { filePath     = bs parent
    , fileNameInfo = Just (dtReg, bs name)
    }


mkDirInfo :: FilePath -> FileInfomation
mkDirInfo path = FileInfomation
    { filePath     = bs path
    , fileNameInfo = Nothing
    }



-- tester konatingeringen, og at den  gir ut Nothing

testsConstructFilePath :: TestTree
testsConstructFilePath = testGroup "constructFilePath"
    [ testCase "Nothing fileNameInfo gir Nothing" $
        constructFilePath (mkDirInfo "/foo")             @?= Nothing

    , testCase "Just fileNameInfo gir full sti" $
        constructFilePath (mkFileInfo "/foo" "bar.txt")  @?= Just "/foo/bar.txt"

    , testCase "tom parent med filnavn" $
        constructFilePath (mkFileInfo "" "bar.txt")      @?= Just "bar.txt"

    , testCase "nestet sti" $
        constructFilePath (mkFileInfo "/a/b/c" "fil.hs") @?= Just "/a/b/c/fil.hs"

    , adjustOption (const (QuickCheckTests 500)) $
      testProperty "gir alltid Nothing for mappe-info" $
        \(ASCIIString p) ->
            constructFilePath (mkDirInfo p) === Nothing

    , adjustOption (const (QuickCheckTests 500)) $
      testProperty "inneholder alltid filnavnet" $
        \(ASCIIString p) (ASCIIString n) ->
            let result = constructFilePath (mkFileInfo p n)
            in  counterexample (show result) $
                    maybe False (n `isSuffixOf`) result
    ]
  where
    isSuffixOf suffix str = suffix == reverse (take (length suffix) (reverse str))



testsTraversal :: TestTree
testsTraversal = testGroup "treverseDirWithSettings"
    [ testCase "tom mappe gir ingen resultater" $

        withSystemTempDirectory "lambdaSearch" $ \tmp -> do
            result <- treverseDirWithSettings (defaultSettings [tmp])
            let files = filter ((/= Nothing) . fileNameInfo) result
            files @?= []

    , testCase "finner én fil" $
        withSystemTempDirectory "lambdaSearch" $ \tmp -> do
            writeFile (tmp <> "/test.txt") "innhold"

            result <- treverseDirWithSettings (defaultSettings [tmp])

            let paths = [constructFilePath fi | fi <- result]

            assertBool "fant ikke test.txt" $
                elem (Just (tmp <> "/test.txt")) paths

    , testCase "skjulte filer inkluderes når hideHidden=False" $

        withSystemTempDirectory "lambdaSearch" $ \tmp -> do
            writeFile (tmp <> "/.skjult") "hemmelig"
            result <- treverseDirWithSettings (defaultSettings [tmp])
            let paths = [constructFilePath fi | fi <- result]
            assertBool "fant ikke .skjult" $
                elem (Just (tmp <> "/.skjult")) paths

    , testCase "skjulte filer ekskluderes når hideHidden=True" $

        withSystemTempDirectory "lambdaSearch" $ \tmp -> do
            writeFile (tmp <> "/.skjult") "hemmelig"
            writeFile (tmp <> "/synlig.txt") "åpen"
            let args = defaultArgs { hideHidden = True }
            result <- treverseDirWithSettings
                        SearchSetting { searchPaths = Just [tmp], arguments = args }
            let paths = [constructFilePath fi | fi <- result]
            assertBool ".skjult skal ikke være med" $

                notElem (Just (tmp <> "/.skjult")) paths
            assertBool "synlig.txt skal være med" $
                elem (Just (tmp <> "/synlig.txt")) paths

    , testCase "filtrerer på extension" $
        withSystemTempDirectory "lambdaSearch" $ \tmp -> do

            writeFile (tmp <> "/Main.hs") ""
            writeFile (tmp <> "/Main.py") ""
            let args = defaultArgs { extention = Just (bs "hs") }

            result <- treverseDirWithSettings
                        SearchSetting { searchPaths = Just [tmp], arguments = args }

            let paths = [constructFilePath fi | fi <- result]

            assertBool "Main.hs skal være med" $
                elem (Just (tmp <> "/Main.hs")) paths

            assertBool "Main.py skal ikke være med" $

                notElem (Just (tmp <> "/Main.py")) paths

    , testCase "ekskluderer mapper" $
        withSystemTempDirectory "lambdaSearch" $ \tmp -> do

            createDirectory (tmp <> "/node_modules")
            writeFile (tmp <> "/node_modules/dep.js") ""
            writeFile (tmp <> "/Main.hs") ""
            let args = defaultArgs { exclude = Just [bs (tmp <> "/node_modules")] }
            result <- treverseDirWithSettings
                        SearchSetting { searchPaths = Just [tmp], arguments = args }
            let paths = [constructFilePath fi | fi <- result]
            assertBool "dep.js skal ikke være med" $
                notElem (Just (tmp <> "/node_modules/dep.js")) paths
            assertBool "Main.hs skal være med" $
                elem (Just (tmp <> "/Main.hs")) paths

    , testCase "traverserer rekursivt" $
        withSystemTempDirectory "lambdaSearch" $ \tmp -> do

            createDirectoryIfMissing True (tmp <> "/a/b")
            writeFile (tmp <> "/a/b/dyp.txt") ""
            result <- treverseDirWithSettings (defaultSettings [tmp])
            let paths = [constructFilePath fi | fi <- result]
            assertBool "fant ikke dyp.txt" $

                elem (Just (tmp <> "/a/b/dyp.txt")) paths
    ]


