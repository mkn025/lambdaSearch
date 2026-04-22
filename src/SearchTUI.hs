{-# LANGUAGE TemplateHaskell #-}
{- HLINT ignore "Use newtype instead of data" -}

module SearchTUI where


import Brick
import Brick.Widgets.Border   (border)
import Graphics.Vty            (defAttr)
import qualified Graphics.Vty  as V

data TuiState = TuiState 
  { paths    :: [FilePath]
  , selected :: Int        -- index of the selected item
  }

type Name = ()


drawItem :: Bool -> FilePath -> Widget Name
drawItem isFocused path =
  let content = padLeftRight 1 $ padTopBottom 0 $ str path
      widget  = border content
  in if isFocused
       then withAttr selectedAttr widget
       else widget


drawItem_ :: Bool -> FilePath -> Widget name
drawItem_ isFocused p =  
    if not isFocused 
    then widget 
    else withAttr selectedAttr widget 
    where
        content = padLeftRight 1 $ padTopBottom 0 $ str p 
        widget  = border content                             


-- | Draw the full UI
drawUI :: TuiState -> [Widget Name]
drawUI st =
  [ padAll 1 $
      vBox (zipWith (\i p -> drawItem (i == selected st) p)
                    [0..] (paths st))
      <=>
      str " "
      <=>
      str "j/k to move, q to quit"
  ]


handleEvent :: BrickEvent Name e -> EventM Name TuiState ()
    -- | enekl imput
handleEvent (VtyEvent (V.EvKey (V.KChar 'k') [])) = modify moveUp
handleEvent (VtyEvent (V.EvKey (V.KChar 'j') [])) = modify moveDown
handleEvent (VtyEvent (V.EvKey (V.KChar 'q') [])) = halt
handleEvent _                                     = return ()


moveUp :: TuiState -> TuiState
moveUp st   = st {selected = max 0 (selected st - 1)}

moveDown :: TuiState -> TuiState
moveDown st = st { selected = min (length (paths st) - 1) (selected st + 1) }

selectedAttr :: AttrName
selectedAttr = attrName "selected"

-- | hovedapp
app :: App TuiState e Name
app = App
  { appDraw         = drawUI
  , appChooseCursor = neverShowCursor
  , appHandleEvent  = handleEvent
  , appStartEvent   = return ()
  , appAttrMap      = const $ attrMap defAttr
      [ (selectedAttr, V.black `on` V.yellow) ]
  }


samplePaths :: [FilePath]
samplePaths =
  [ "/home/user/documents/report.pdf"
  , "/home/user/pictures/vacation.png"
  , "/home/user/projects/main.hs"
  , "/etc/hosts"
  , "/var/log/syslog"
  ]


main :: IO ()
main = do

  let initialState = TuiState { paths = samplePaths, selected = 0 }
  finalState <- defaultMain app initialState

  putStrLn $ "Du vlagte" ++ paths finalState !! selected finalState
