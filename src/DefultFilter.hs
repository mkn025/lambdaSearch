module DefultFilter where

import TraversalSettings (Arguments(..))


defaultArguments  :: Arguments
defaultArguments  = Arguments {
      regxPattern    = Nothing
    , exclude        = Nothing
    , extention      = []
    , hideHidden     = True
    , applyedCommand = Nothing
}




