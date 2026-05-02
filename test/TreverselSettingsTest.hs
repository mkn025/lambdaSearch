module TreverselSettingsTest (mainTreverselSettingsTest) where


import Test.Tasty
import Test.Tasty.HUnit
import Test.Tasty.QuickCheck
import qualified Data.ByteString.Char8 as BC

import TraversalSettings

import Utils (AsciiString(AsciiString), bs, defaultArgs )


mainTreverselSettingsTest :: TestTree 
mainTreverselSettingsTest =  testGroup "Parser teste" [
       testConvertions 
     , testsSafeHead 
     , testsSafeTail 
     , testsHiddenFilter
     , testsDisallowFilter 
     , testsExtentionFilter 
     , testsGetRexPattern ]
 





testConvertions :: TestTree
testConvertions = adjustOption (const (QuickCheckTests 1_000)) $ testProperty
  "Test many convertions" $
  \(AsciiString s) -> s ===  convertToString (convertString s)



--------------------------------------------------
-- Tester head og tail --
--------------------------------------------------
testsSafeHead :: TestTree
testsSafeHead = testGroup "safeHead"
    [ testCase "empty gir Nothing" $
        safeHead BC.empty   @?= Nothing

    , testCase "enkelt tegn gir Just tegnet" $
        safeHead (bs "a")   @?= Just 'a'

    , testCase "tar kun første tegn" $
        safeHead (bs "abc") @?= Just 'a'

    , adjustOption (const (QuickCheckTests 1_000)) $
      testProperty "ikke-tom streng gir alltid Just" $

        \(AsciiString s) -> not (null s) ==>
            safeHead (bs s) === Just (head s)
    ]

testsSafeTail :: TestTree
testsSafeTail = testGroup "safeTail"
    [ testCase "empty gir Nothing" $
        safeTail BC.empty   @?= Nothing

    , testCase "enkelt tegn gir Just empty" $
        safeTail (bs "a")   @?= Just BC.empty

    , testCase "fjerner første tegn" $
        safeTail (bs "abc") @?= Just (bs "bc")

    , adjustOption (const (QuickCheckTests 1_000)) $
      testProperty "ikke-tom: lengde redusert med 1" $
        \(AsciiString s) -> not (null s) ==>
             (BC.length <$> safeTail (bs s)) === Just (length s - 1)
    ]




testsHiddenFilter :: TestTree
testsHiddenFilter = testGroup "getHiddenFilter"
    [ testCase "hideHidden=False: tar alltid med" $
        getHiddenFilter defaultArgs (bs ".hidden") @?= True

    , testCase "hideHidden=True: skjuler dot-fil" $
        getHiddenFilter args (bs ".hidden")        @?= False

    , testCase "hideHidden=True: tar med vanlig fil" $
        getHiddenFilter args (bs "vanlig.txt")     @?= True

    , testCase "hideHidden=True: tom bytestring tas med" $
        getHiddenFilter args BC.empty              @?= True

    , adjustOption (const (QuickCheckTests 1_000)) $
      testProperty "hideHidden=False filtrerer aldri bort" $
        \(ASCIIString s) ->
            getHiddenFilter defaultArgs (bs s) === True
    ]
  where
    args = defaultArgs { hideHidden = True }

 

testsDisallowFilter :: TestTree
testsDisallowFilter = testGroup "getDisallowFilter"
    [ testCase "ingen exclude: tar alltid med" $
        getDisallowFilter defaultArgs (bs "/foo/bar")                              @?= True

    , testCase "filepath med ekskludert prefix: filtreres bort" $
        getDisallowFilter (withExclude ["/node_modules"]) (bs "/node_modules/foo") @?= False

    , testCase "filepath uten ekskludert prefix: tas med" $
        getDisallowFilter (withExclude ["/node_modules"]) (bs "/src/foo")          @?= True

    , testCase "flere excludes: matcher riktig" $
        getDisallowFilter (withExclude ["/a", "/b"]) (bs "/b/fil")                 @?= False

    , adjustOption (const (QuickCheckTests 1_000)) $
      testProperty "ingen exclude filtrerer aldri bort" $
        \(PrintableString s) ->
            getDisallowFilter defaultArgs (bs s) === True
    ]
  where
    withExclude xs = defaultArgs { exclude = Just (map bs xs) }



testsExtentionFilter :: TestTree
testsExtentionFilter = testGroup "getExtentionFilter"
    [ testCase "ingen extention: tar alltid med" $
        getExtentionFilter defaultArgs (bs "foo.hs")        @?= True

    , testCase "riktig extention: tas med" $
        getExtentionFilter (withExt "hs") (bs "Main.hs")    @?= True

    , testCase "feil extention: filtreres bort" $
        getExtentionFilter (withExt ".hs") (bs "Main.agda") @?= False

    , testCase "fil uten extention: filtreres bort" $
        getExtentionFilter (withExt ".hs") (bs "Makefile")  @?= False

    , testCase "tom filepath: filtreres bort" $
        getExtentionFilter (withExt ".hs") BC.empty         @?= False

    , adjustOption (const (QuickCheckTests 1_000)) $
      testProperty "ingen extention filtrerer aldri bort" $
        \(ASCIIString s) ->
            getExtentionFilter defaultArgs (bs s) === True
    ]
  where
    withExt e = defaultArgs { extention = Just (bs e) }



testsGetRexPattern :: TestTree
testsGetRexPattern = testGroup "getRexPattern"
    [ testCase "Nothing: matcher alltid" $

        getRexPattern Nothing (bs "hvasomhelst")              @?= True

    , testCase "Just regex: matcher korrekt streng" $
        getRexPattern (compileRegexFilter args) (bs "foo.hs") @?= True

    , testCase "Just regex: avviser ikke-matchende streng" $
        getRexPattern (compileRegexFilter args) (bs "foo.py") @?= False

    , adjustOption (const (QuickCheckTests 1_000)) $
      testProperty "Nothing matcher alltid uansett input" $
        \(ASCIIString s) ->
            getRexPattern Nothing (bs s) === True
    ]
  where
    args = defaultArgs { regxPattern = Just (bs "\\.hs$") }



