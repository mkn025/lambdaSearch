module FileSystem.DefultIgnore where

import System.Posix.Directory.Internals (
    DirStream(..)
    )


import Control.Monad.Trans.Maybe (MaybeT (runMaybeT), hoistMaybe)

import System.Posix (
      getWorkingDirectory
    , openDirStream
    , readDirStream
    , fileExist
    , getFileStatus
    , isDirectory
    )

import Control.Monad.IO.Class( liftIO)
import Control.Monad.Trans.Class (MonadTrans(lift))
import Data.Text.Internal.Fusion.Size (isEmpty)
import Control.Monad (guard)



getUnwatedFiles :: IO [FilePath]
getUnwatedFiles = filterUnwantedGitignoreFiles unwantedFiles <$> allFileInGitIgnore

unwantedFiles :: [FilePath]
unwantedFiles = [",",""," "]

filterUnwantedGitignoreFiles :: [FilePath] -> [FilePath] -> [FilePath]
filterUnwantedGitignoreFiles unwf = filter (`notElem` unwf)


allFileInGitIgnore :: IO [FilePath]
allFileInGitIgnore = do
    path   <- fullGitPath       <$> getWorkingDirectory
    notDir <- not . isDirectory <$> getFileStatus path
    exist  <- fileExist path
    readIfTrue (exist && notDir) path
    where
        fullGitPath :: FilePath -> FilePath
        fullGitPath cwd = cwd  <> "/" <> ".gitignore"

        readIfTrue :: Bool -> FilePath -> IO [FilePath]
        readIfTrue  False _   = pure  []
        readIfTrue  True path = lines <$> readFile path


allFilesInDir :: IO [FilePath]
allFilesInDir =  getWorkingDirectory >>= getFilesInDir

getFilesInDir :: FilePath -> IO [FilePath]
getFilesInDir fp  = openDirStream fp >>= readEnitreDirStream []

readEnitreDirStream :: [FilePath] -> DirStream -> IO [FilePath]
readEnitreDirStream lst ds = readDirStream ds >>= actOnDir
    where
        actOnDir :: FilePath -> IO [FilePath]
        actOnDir (null -> True) = pure lst
        actOnDir file           = readEnitreDirStream (file:lst) ds



type MaybeIO a = MaybeT IO a

allFilesInDir_ :: MaybeIO [FilePath]
allFilesInDir_ = do
    files      <- lift getWorkingDirectory
    allFiles   <- lift . getFilesInDir $ files 
    valiedateFilePath allFiles 



valiedateFilePath ::  Applicative m => [FilePath] -> MaybeT m [FilePath]
valiedateFilePath [] = hoistMaybe Nothing
valiedateFilePath xs = hoistMaybe . Just $  filter (`notElem` un ) xs
    where 
    un = [".",".."]

bar :: IO (Maybe [FilePath])
bar = runMaybeT allFilesInDir_















 




