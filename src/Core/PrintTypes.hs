module Core.PrintTypes (
      PathType      (..)
    , OutputColor   (..)
    , PrintSettings (..)
    ) where


data PathType = RelativeFilePath | AbsolutPathFilePath 
    deriving (Eq,Show)

data OutputColor = Redish | Greeny | Blueish
    deriving (Eq, Show)

data PrintSettings = PrintSettings{
      pathType   :: PathType
    , matchColor :: OutputColor
    } deriving (Eq,Show)

