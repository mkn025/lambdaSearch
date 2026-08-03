module FileSystem.RawFilePathUtils where

import Core.TraversalTypes (
      DirType        (..)
    , AbsolutPath    (..)
    , RelativPath    (..)
    , FilePaths      (..)
    , DirContent     (..)
    , FileInfomation (..)
    )


import System.FilePath.Posix.ByteString ((</>))
import System.Posix.ByteString.FilePath (RawFilePath)
import System.Posix.Files.ByteString    (isDirectory, getFileStatus)
import Core.Filters                     (convertToString )


dtDir :: DirType
dtDir = DirType 4

concatRelativeFilePath :: RelativPath RawFilePath -> RelativPath RawFilePath -> Maybe DirContent -> RelativPath RawFilePath
concatRelativeFilePath old new Nothing = old <> new
concatRelativeFilePath old new (Just DirContent {..}) = if pure name == new
                                                        then old
                                                        else old <> new 

checkIfDir :: AbsolutPath RawFilePath -> IO Bool
checkIfDir (AbsolutPath path)  = isDirectory <$> getFileStatus path

unpackAbsolutPath :: AbsolutPath a -> a
unpackAbsolutPath (AbsolutPath a) = a


unpackRelativPath :: RelativPath a -> a
unpackRelativPath (RelativPath a) = a

createFileInformation :: FilePaths -> Maybe DirContent -> FileInfomation
createFileInformation fp dc = FileInfomation{
      filePaths    = fp
    , fileNameInfo = dc
    }



-- Hjelpemeothde som lager helefilstien dersom, dersom det er en sti
constructFilePath :: FileInfomation -> Maybe String
constructFilePath FileInfomation{fileNameInfo = Nothing}                                          = Nothing
constructFilePath FileInfomation{fileNameInfo = (Just DirContent{..}), filePaths = FilePaths{..}} = Just . convertToString $ unpackAbsolutPath  absoluteFilePath </> name
