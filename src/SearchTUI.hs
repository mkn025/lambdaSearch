{-# LANGUAGE TemplateHaskell #-}

import Brick
import Lens.Micro ()
import Brick.Widgets.Edit (Editor)
import Data.Text (Text)

data MyState n = MyState { _editor :: Editor Text n }

makeLenses ''MyState


main :: IO ()
main = simpleMain ui


ui :: Widget ()
ui = str "Hello, world!"



data App s e n = App {
         appDraw         :: s -> [Widget n]
        , appChooseCursor :: s -> [CursorLocation n] -> Maybe (CursorLocation n)
        , appHandleEvent  :: BrickEvent n e -> EventM n s ()
        , appStartEvent   :: EventM n s ()
        , appAttrMap      :: s -> AttrMap
        }




handleEvent :: BrickEvent n e -> EventM n s () -- skal 
handleEvent = undefined 

