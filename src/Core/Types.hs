module Core.Types (
      DirType     (..)
    , AbsolutPath (..)
    , RelativPath (..)
    , FilePaths   (..)

    ) where

import System.Posix.ByteString.FilePath             (RawFilePath)

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


data FilePaths = FilePaths {
          relativeFilePath :: RelativPath RawFilePath
        , absoluteFilePath :: AbsolutPath RawFilePath
    } deriving (Eq,Show)


    -- Arguments,
    -- SearchSetting,
    -- Args,
    -- ConstrucedCommand,
    -- 
    -- OutputColor,
    -- PathType,
    -- PrintSettings,
    -- 
    -- DirType,
    -- DirContent,
    -- FilePaths,
    -- FileInfomation,
    -- 
    -- defaultArguments
    -- NOTHING but data/newtype decls + trivial instances

