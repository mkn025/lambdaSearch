module FileSystem.DefultIgnore where

import System.Posix.Directory.Internals (
      DirStream(..)
    )

import System.Posix (
      getWorkingDirectory
    , openDirStream
    , fileExist
    , getFileStatus
    , isDirectory
    , readDirStreamMaybe
    , closeDirStream
    )

import Control.Monad.Except (
      runExceptT
    , ExceptT(..)
    )

import Control.Monad        (
      unless
    , (<=<)
    )

import Control.Monad.Trans        (lift)
import Control.Monad.Trans.Except (throwE)

fooBar = flip (.)

getUnwatedFiles :: IO [FilePath]
getUnwatedFiles = actOnFiles =<< runExceptT getPathsInGitIgnore
    where
        actOnFiles (Left  feilMsg) = print ("Hadde en feil " ++ show feilMsg ) >> pure []
        actOnFiles (Right filer)   = pure filer

data FilFeil =
      FantIkkeFilen
    | IkkeEnDir
    | MappeStrømFeil
    deriving  Show

type IODirExeption a = ExceptT FilFeil IO a

filterUnwanted :: [FilePath] -> [FilePath]
filterUnwanted = filter (`notElem` unwantedFiles )
    where
        unwantedFiles = [",",""," "]


getPathsInGitIgnore :: IODirExeption [FilePath]
getPathsInGitIgnore = do
    file  <- validateDirectory . fullGitPath =<< lift getWorkingDirectory
    lift $ lines <$> readFile file
    where
        fullGitPath :: FilePath -> FilePath
        fullGitPath cwd = cwd  <> "/" <> ".gitignore"

allFilesInDir :: IODirExeption [FilePath]
allFilesInDir = (getFilesInDir <=< validateDirectory) =<< lift getWorkingDirectory

getFilesInDir :: FilePath -> IODirExeption [FilePath]
getFilesInDir = readEnitreDirStream [ ] <=<  lift . openDirStream <=<  validateDirectory


readEnitreDirStream :: [FilePath] -> DirStream -> IODirExeption [FilePath]
readEnitreDirStream lst ds = do
    dirStream <- lift . readDirStreamMaybe $ ds
    maybe (throwE MappeStrømFeil) actOnFilePath dirStream 
    where
        actOnFilePath :: FilePath -> IODirExeption [FilePath]
        actOnFilePath (null -> True) = lift (closeDirStream  ds) >> pure lst
        actOnFilePath file           = readEnitreDirStream (file:lst) ds




validateDirectory :: FilePath -> IODirExeption FilePath
validateDirectory fp = do
    exists <- lift $ fileExist fp
    unless exists (throwE FantIkkeFilen)

    isDir  <- lift $ isDirectory <$> getFileStatus fp
    unless isDir (throwE IkkeEnDir)

    pure fp


