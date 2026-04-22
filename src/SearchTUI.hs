module SearchTUI (mainTUI) where

import TraverselsFunctions (treverseDirWithSettings, constructFilePath)
import ParseInput          (runParserIO)

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
      , AttrName
      , App(..)
      , EventM
      , BrickEvent(VtyEvent)
      , ViewportType(Vertical)
      , Widget
      , zoom
      , get
    )

import qualified Graphics.Vty as V
import Brick.Widgets.Border   (border, hBorder)
import Brick.Widgets.Edit     (Editor, editor, renderEditor,
                               handleEditorEvent, getEditContents)
import Graphics.Vty           (defAttr)
import Control.Monad.IO.Class (liftIO)
import Lens.Micro.Type        (Lens')
import Data.Maybe             (mapMaybe)


data Mode = Browsing   | Searching deriving (Eq)
data Name = MyViewport | SearchBox deriving (Eq, Ord, Show)

data TuiState = TuiState
  { paths        :: [FilePath]
  , selected     :: Int
  , searchEditor :: Editor String Name
  , mode         :: Mode
  }


drawItem :: Bool -> FilePath -> Widget Name
drawItem isFocused p =
    if not isFocused
    then widget
    else visible $ withAttr selectedAttr widget
  where
    widget = border $ padLeftRight 1 $ str p

drawUI :: TuiState -> [Widget Name]
drawUI st =
  [ padAll 1 $
      
      searchBox
      <=>
      hBorder
      <=>
      viewport MyViewport Vertical
        (vBox (
            zipWith (\i p -> drawItem (i == selected st) p)
            [0..]
            ((take 100 . paths) st))
        )
      <=>
      str " "
      <=>
      helpLine
  ]
  where
    searchBox =
      str "Search: "
      <+> renderEditor (str . unlines) (mode st == Searching) (searchEditor st)

    helpLine = case mode st of
      Browsing  -> str "j/k: move   /: search   q: quit     |     search queries:  -p regex -e extenton ..."
      Searching -> str "Enter: run search   Esc: cancel"


handleEvent :: BrickEvent Name e -> EventM Name TuiState ()
handleEvent (VtyEvent (V.EvKey V.KUp [] ))        = modify  moveUp
handleEvent (VtyEvent (V.EvKey V.KDown [] ))      = modify moveDown
handleEvent (VtyEvent (V.EvKey (V.KChar 'q') [])) = do
    st <- get
    case mode st of
        Searching -> pure ()
        Browsing  -> halt

handleEvent (VtyEvent (V.EvKey (V.KChar '/') [])) = modify (\st -> st { mode = Searching })
handleEvent (VtyEvent (V.EvKey V.KEsc []))        = modify (\st -> st { mode = Browsing })
handleEvent (VtyEvent (V.EvKey V.KEnter []))      = do

    st <- get
    let query = concat (getEditContents (searchEditor st))  
    results <- liftIO $ runSearch query --løfter elegeant ut 
    modify (\s -> s { paths    = results
                    , selected = 0
                    , mode     = Browsing })

handleEvent ev = do
    st <- get
    case mode st of
      Searching -> zoom searchEditorL (handleEditorEvent ev)
      Browsing  -> pure ()


searchEditorL :: Lens' TuiState (Editor String Name)
searchEditorL f st = (\e -> st { searchEditor = e }) <$> f (searchEditor st)

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

mainTUI :: IO ()
mainTUI = do
  initialPaths <- runSearch ""          
  let initialState = TuiState
        { paths        = initialPaths
        , selected     = 0
        , searchEditor = editor SearchBox (Just 1) "" 
        , mode         = Browsing
        }
  finalState <- defaultMain app initialState
  putStrLn $ "Du valgte: " ++ (paths finalState !! selected finalState)
