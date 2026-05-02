module SearchTUI (mainTUI) where

import TraverselsFunctions (treverseDirWithSettings, constructFilePath, executeOnFile)
import ParseInput          (runParserIO)
import TraversalSettings   (Args (..), convertString)

import Brick (
        attrMap
      , attrName
      , defaultMain
      , halt
      , showFirstCursor
      , on
      , (<+>)
      , (<=>)
      , padAll
      , padLeftRight
      , str
      , vBox
      , viewport
      , visible
      , withAttr
      , modify
      , nestEventM
      , AttrName
      , App(..)
      , EventM
      , BrickEvent(VtyEvent)
      , ViewportType(Vertical)
      , Widget
      , get )


import qualified Graphics.Vty as V
import Brick.Widgets.Border   (border, hBorder)
import Brick.Widgets.Edit     (Editor, editor, renderEditor,
                               handleEditorEvent, getEditContents)
import Graphics.Vty           (defAttr)
import Control.Monad.IO.Class (liftIO)
import System.Environment     (lookupEnv )
import Data.Maybe             (mapMaybe)


data Mode = Browsing   | Searching deriving (Eq)
data Name = MyViewport | SearchBox deriving (Eq, Ord, Show)

data TuiState = TuiState {
    paths        :: [FilePath]
  , selected     :: Int
  , searchEditor :: Editor String Name
  , mode         :: Mode
  , startEditor  :: Bool
  }


drawItem :: Bool -> FilePath -> Widget Name
drawItem isFocused p =
    if not isFocused
    then widget
    else visible $ withAttr selectedAttr widget
  where
    widget = border $ padLeftRight 1 $ str p

drawUI :: TuiState -> [Widget Name]
drawUI st = [ 
      padAll 1 $
      searchBox
      <=>
      hBorder
      <=>
      viewport MyViewport Vertical
        (vBox (zipWith (\i p -> drawItem (i == selected st) p)
        [0..]
        ((take 100 . paths) st)))
      <=>
      str " "
      <=>
      helpLine st
      <=>
      staringEditorText st 
      ]
  where
    searchBox =
      str "Search: "
      <+> renderEditor (str . unlines) (mode st == Searching) (searchEditor st)
    helpLine (mode  -> Browsing)  = str "ctrl-n/ctrl-p: move /: search   ctrl-q: quit  ctrl-e: open in editor (when cloing )   |   search queries:  -p regex -e extenton ..."
    helpLine (mode -> Searching)  = str "Enter: run search   Esc: cancel"
    staringEditorText (startEditor -> True)  = str "Staring editor when closing"
    staringEditorText (startEditor -> False) = str "Not Staring editor when closing"




stopInputWhileBrowing :: EventM Name TuiState () -> EventM Name TuiState ()
stopInputWhileBrowing action  = get >>= checkBrowsing 
    where 
        checkBrowsing (mode -> Searching) = pure ()
        checkBrowsing (mode -> Browsing)  = action 



handleEvent :: BrickEvent Name e -> EventM Name TuiState ()
handleEvent (VtyEvent (V.EvKey (V.KChar 'n') [V.MCtrl])) = stopInputWhileBrowing . modify $ moveDown
handleEvent (VtyEvent (V.EvKey (V.KChar 'p') [V.MCtrl])) = stopInputWhileBrowing . modify $ moveUp
handleEvent (VtyEvent (V.EvKey (V.KChar 'q') [V.MCtrl])) = stopInputWhileBrowing halt
handleEvent (VtyEvent (V.EvKey (V.KChar 'c') [V.MCtrl])) = stopInputWhileBrowing halt
handleEvent (VtyEvent (V.EvKey (V.KChar 'e') [V.MCtrl])) = stopInputWhileBrowing $ get >>= (\ist -> modify (\st -> st {startEditor  = not . startEditor  $ ist }))
handleEvent (VtyEvent (V.EvKey (V.KChar '/') []))        = modify (\st -> st { mode = Searching })
handleEvent (VtyEvent (V.EvKey  V.KEsc       []))        = modify (\st -> st { mode = Browsing })
handleEvent (VtyEvent (V.EvKey  V.KEnter     []))        = do
    st <- get
    let query = concat (getEditContents (searchEditor st))  
    results <- liftIO $ runSearch query 
    modify (\s -> s { paths    = results
                    , selected = 0
                    , mode     = Browsing })
handleEvent ev = do
    st <- get
    case mode st of
      Searching -> do
          -- gjør slik at vi bare kan håndere searchEditor state
          newEditor <- nestEventM (searchEditor st) (handleEditorEvent ev)
          modify (\s -> s { searchEditor = fst newEditor })
      Browsing  -> pure ()


runSearch :: String -> IO [FilePath]
runSearch (null -> True ) = pure []
runSearch query = do
    settings <- runParserIO query
    results  <- treverseDirWithSettings settings
    pure $ mapMaybe constructFilePath results


moveUp, moveDown :: TuiState -> TuiState -- begge har samme type  så vi kan putte de her
moveUp   st = st { selected = max 0 (selected st - 1) }
moveDown st = st { selected = min (length (paths st) - 1) (selected st + 1) }

selectedAttr :: AttrName
selectedAttr = attrName ""

app :: App TuiState e Name
app = App
  { appDraw         = drawUI
  , appChooseCursor = showFirstCursor   -- lets the editor show a cursor
  , appHandleEvent  = handleEvent
  , appStartEvent   = pure ()
  , appAttrMap      = const $ attrMap defAttr
      [ (selectedAttr, V.black `on` V.yellow) ]
  }

-- litt shady, men men
openInEditor :: TuiState -> IO ()
openInEditor (startEditor -> False) = pure ()
openInEditor st = do
    ed <- lookupEnv "EDITOR"
    case ed of
        Nothing   -> putStrLn "fant ikke noe editor i env var"
        (Just e) -> do
                let selectedPath =
                       convertString 
                     . fst
                     . head
                     . filter ((==selected st) . snd ) 
                     $ zip (paths st) [0..]
                let cmd = (e, [PathToSubs])
                executeOnFile cmd selectedPath 

mainTUI :: IO ()
mainTUI = do
  initialPaths <- runSearch ""          
  let initialState = TuiState
        { paths        = initialPaths
        , selected     = 0
        , searchEditor = editor SearchBox (Just 1) ""
        , mode         = Browsing
        , startEditor  = False
        }
  finalState <- defaultMain app initialState
  openInEditor finalState 
