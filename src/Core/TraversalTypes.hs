module Core.TraversalTypes (
      DirType        (..)
    , AbsolutPath    (..)
    , RelativPath    (..)
    , FilePaths      (..) 
    , DirContent     (..)
    , FileInfomation (..)
    )
    where

import System.Posix.ByteString.FilePath (RawFilePath)



newtype DirType = DirType Int
    deriving (Eq, Show)

newtype AbsolutPath a = AbsolutPath a
    deriving (Eq,Show,Functor)

newtype RelativPath  a = RelativPath a
    deriving (Eq,Show,Functor)

instance Applicative AbsolutPath where
    pure = AbsolutPath
    AbsolutPath  f <*>  AbsolutPath x  = AbsolutPath (f  x)

instance Applicative RelativPath where
    pure = RelativPath
    RelativPath  f <*>  RelativPath x  = RelativPath (f  x)

instance (Semigroup a) => Semigroup (AbsolutPath a) where
    (AbsolutPath a) <> (AbsolutPath b) = AbsolutPath (a <> b)

instance (Semigroup a) => Semigroup (RelativPath a) where
    (RelativPath a) <> (RelativPath b) = RelativPath (a <> b)




data FilePaths = FilePaths {
          relativeFilePath :: RelativPath RawFilePath
        , absoluteFilePath :: AbsolutPath RawFilePath
    } deriving (Eq,Show)


data DirContent =  DirContent {
      fileType       :: DirType
    , name           :: RawFilePath
    } deriving (Eq,Show)
     

data FileInfomation = FileInfomation{
      filePaths    :: FilePaths -- Nothing dersom det er en mappe
    , fileNameInfo :: Maybe DirContent -- Nothing dersom det er en mappe
} deriving (Eq,Show)








