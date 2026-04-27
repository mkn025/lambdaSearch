module ParserTest (parserTests) where



import Test.Tasty
import Test.Tasty.HUnit
import Test.Tasty.QuickCheck
import qualified Data.ByteString.Char8 as BC
import Data.Maybe (isNothing )

import ParseInput        (runMyParser, parseLamdaSearch)
import TraversalSettings


-- Kjører parseren og feiler testen om den ikke klarer å parse
mustParse :: String -> IO SearchSetting
mustParse input = case runMyParser parseLamdaSearch input of
    Right ss  -> pure ss
    Left  err -> assertFailure ("Parse feilet uventet:\n" <> err)

-- Asserter at parseren feiler
-- sksal nok bruke
mustFail :: String -> IO ()
mustFail input = case runMyParser parseLamdaSearch input of
    Left  _  -> pure ()
    Right ss -> assertFailure ("Forventet feil, men fikk: " <> show ss)

bs :: String -> BC.ByteString
bs = BC.pack

emptyArgs :: Arguments
emptyArgs = Arguments
    { regxPattern    = Nothing
    , exclude        = Nothing
    , extention      = Nothing
    , hideHidden     = False
    , applyedCommand = Nothing
    }


parserTests :: TestTree
parserTests = testGroup "Parser teste"
    [ testsNoFlags
    , testsPaths
    , testsPatternFlag
    , testsHiddenFlag
    , testsExtentionFlag
    , testsIgnoreFlag
    , testsExecuteFlag
    , testsCombined
    ]



testsNoFlags :: TestTree
testsNoFlags = testGroup "ingen flagg"
    [ testCase "punktum gir ingen sti og tomme args" $ do
        ss <- mustParse "."
        searchPaths ss @?= Nothing
        arguments   ss @?= emptyArgs

    , testCase "tom streng gir ingen sti og tomme args" $ do
        ss <- mustParse ""
        searchPaths ss @?= Nothing
        arguments   ss @?= emptyArgs

    , testCase "bare whitespace" $ do
        ss <- mustParse "   "
        searchPaths ss @?= Nothing
        arguments   ss @?= emptyArgs
    ]

-- ── Stier ─────────────────────────────────────────────────────────────────────

testsPaths :: TestTree
testsPaths = testGroup "stier"
    [ testCase "absolutt sti" $ do
        ss <- mustParse "/home/foo"
        searchPaths ss @?= Just ["/home/foo"]

    , testCase "to stier med mellomrom" $ do
        ss <- mustParse "/home/foo /var/bar"
        searchPaths ss @?= Just ["/home/foo", "/var/bar"]

    , testCase "sti med anførselstegn" $ do
        ss <- mustParse "\"/home/min mappe\""
        searchPaths ss @?= Just ["/home/min mappe"]

    , testCase "sti med anførselstegn + flagg etterpå" $ do
        ss <- mustParse "\"/home/foo\" -a"
        searchPaths ss            @?= Just ["/home/foo"]
        hideHidden (arguments ss) @?= True

    , testCase "punktum ignorerer etterfølgende stier" $ do
        -- punktum-grenen avslutter sti-parsingen
        ss <- mustParse ". -a"
        searchPaths ss @?= Nothing

    , testCase "tom ManyPaths gir Nothing" $ do
        -- ingen sti og ingen punktum → tom pathsUntilFlag
        ss <- mustParse "-a"
        searchPaths ss @?= Nothing
    ]

-- ── -p / --pattern ────────────────────────────────────────────────────────────

testsPatternFlag :: TestTree
testsPatternFlag = testGroup "-p / --pattern"
    [ testCase "-p setter regex-pattern" $ do
        ss <- mustParse ". -p foo"
        regxPattern (arguments ss) @?= Just (bs "foo")

    , testCase "--pattern lang form" $ do
        ss <- mustParse ". --pattern foo"
        regxPattern (arguments ss) @?= Just (bs "foo")

    , testCase "-p med regex-tegn" $ do
        ss <- mustParse ". -p \\.hs$"
        regxPattern (arguments ss) @?= Just (bs "\\.hs$")

    , testCase "uten -p: Nothing" $ do
        ss <- mustParse "."
        regxPattern (arguments ss) @?= Nothing

    , testCase "-P stor bokstav virker (string' er case-insensitive)" $ do
        ss <- mustParse ". -P foo"
        regxPattern (arguments ss) @?= Just (bs "foo")
    ]

-- ── -a / --show--dots ─────────────────────────────────────────────────────────

testsHiddenFlag :: TestTree
testsHiddenFlag = testGroup "-a / --show--dots"
    [ testCase "-a setter hideHidden=True" $ do
        ss <- mustParse ". -a"
        hideHidden (arguments ss) @?= True

    , testCase "--show--dots lang form" $ do
        ss <- mustParse ". --show--dots"
        hideHidden (arguments ss) @?= True

    , testCase "uten -a: hideHidden=False" $ do
        ss <- mustParse "."
        hideHidden (arguments ss) @?= False
    ]

-- ── -e / --extention ─────────────────────────────────────────────────────────

testsExtentionFlag :: TestTree
testsExtentionFlag = testGroup "-e / --extention"
    [ testCase "-e setter extention" $ do
        ss <- mustParse ". -e hs"
        extention (arguments ss) @?= Just (bs ".hs")

    , testCase "--extention lang form" $ do
        ss <- mustParse ". --extention py"
        extention (arguments ss) @?= Just (bs ".py")

    , testCase "uten -e: Nothing" $ do
        ss <- mustParse "."
        extention (arguments ss) @?= Nothing
    ]

-- ── -i / --ignore ─────────────────────────────────────────────────────────────

testsIgnoreFlag :: TestTree
testsIgnoreFlag = testGroup "-i / --ignore"
    [ testCase "-i med én sti" $ do
        ss <- mustParse ". -i /node_modules"
        exclude (arguments ss) @?= Just [bs "/node_modules"]

    , testCase "-i med to stier" $ do
        ss <- mustParse ". -i /foo /bar"
        exclude (arguments ss) @?= Just [bs "/foo", bs "/bar"]

    , testCase "--ignore lang form" $ do
        ss <- mustParse ". --ignore /dist"
        exclude (arguments ss) @?= Just [bs "/dist"]

    , testCase "uten -i: Nothing" $ do
        ss <- mustParse "."
        exclude (arguments ss) @?= Nothing
    ]

-- ── -x / --execute ───────────────────────────────────────────────────────────

testsExecuteFlag :: TestTree
testsExecuteFlag = testGroup "-x / --execute"
    [ testCase "-x med program og ingen args" $ do
        ss <- mustParse ". -x echo"
        applyedCommand (arguments ss) @?= Just ("echo", [])

    , testCase "-x med PathToSubs ({})" $ do
        ss <- mustParse ". -x cp {} /dst"
        applyedCommand (arguments ss) @?= Just ("cp", [PathToSubs, Text "/dst"])

    , testCase "-x med bare tekst-args" $ do
        ss <- mustParse ". -x echo hello world"
        applyedCommand (arguments ss) @?= Just ("echo", [Text "hello", Text "world"])

    , testCase "-x med flagg-aktig arg (f.eks. ls -la)" $ do
        ss <- mustParse ". -x ls -la"
        applyedCommand (arguments ss) @?= Just ("ls", [Text "-la"])

    , testCase "flere {} i samme kommando" $ do
        ss <- mustParse ". -x cp {} {}"
        applyedCommand (arguments ss) @?= Just ("cp", [PathToSubs, PathToSubs])

    , testCase "uten -x: Nothing" $ do
        ss <- mustParse "."
        applyedCommand (arguments ss) @?= Nothing
    ]

-- ── Kombinasjoner ─────────────────────────────────────────────────────────────

testsCombined :: TestTree
testsCombined = testGroup "kombinerte flagg"
    [ testCase "sti + pattern + hidden" $ do
        ss <- mustParse "/src -p foo -a"
        searchPaths ss             @?= Just ["/src"]
        regxPattern (arguments ss) @?= Just (bs "foo")
        hideHidden  (arguments ss) @?= True

    , testCase "alle flagg sammen" $ do
        ss <- mustParse ". -p foo -a -e .hs -i /dist -x echo {}"
        let args = arguments ss
        regxPattern    args @?= Just (bs "foo")
        hideHidden     args @?= True
        extention      args @?= Just (bs "hs")
        exclude        args @?= Just [bs "/dist"]
        applyedCommand args @?= Just ("echo", [PathToSubs])

    , testCase "rekkefølge på flagg spiller ingen rolle" $ do
        ss1 <- mustParse ". -a -e .hs"
        ss2 <- mustParse ". -e .hs -a"
        arguments ss1 @?= arguments ss2

    , testCase "duplikate flagg: siste vinner (foldl)" $ do
        -- foldl' betyr siste -e overskriver første
        ss <- mustParse ". -e .hs -e .py"
        extention (arguments ss) @?= Just (bs ".py")

    , adjustOption (const (QuickCheckTests 500)) $
      testProperty "punktum gir alltid Nothing searchPaths" $
        \(PrintableString flags) ->
            -- punktum låser sti-parsingen uansett hva som kommer etter
            case runMyParser parseLamdaSearch (". " <> flags) of
                Left  _  -> True          -- parse-feil er ok her
                Right ss -> isNothing (searchPaths ss)
    ]




