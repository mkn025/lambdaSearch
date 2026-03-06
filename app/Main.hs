module Main where

import qualified MyLib (someFunc)
import qualified SearchFiles (testC )
import SearchFiles (testC)


--Dette er en test kommentart:
--Dette er en test kommentart:
main = do
    a <- testC 
    print a


