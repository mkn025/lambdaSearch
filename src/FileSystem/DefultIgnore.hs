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
    , readDirStreamMaybe, closeDirStream
    )

import Control.Monad.Except (
      runExceptT
    , ExceptT(..)
    )
import Control.Monad.Trans        (lift)
import Control.Monad.Trans.Except (throwE)
import Control.Monad              (unless, (<=<))
import Control.Exception (bracket)

getUnwatedFiles :: IO [FilePath]
getUnwatedFiles = actOnFiles =<< runExceptT getPathsInGitIgnore
    where
        actOnFiles (Left feilMsg) = print ("Hadde en feil " ++ show feilMsg ) >> pure []
        actOnFiles (Right filer)  = pure filer


data FilFeil =
      FantIkkeFilen
    | IkkeEnDir
    | DirStreamFeil
    deriving  Show

type ExceptTDirecetory a = ExceptT FilFeil IO a

filterUnwanted :: [FilePath] -> [FilePath]
filterUnwanted = filter (`notElem` unwantedFiles )
    where
        unwantedFiles :: [FilePath]
        unwantedFiles = [",",""," "]


getPathsInGitIgnore :: ExceptTDirecetory [FilePath]
getPathsInGitIgnore = do
    cwd  <- fullGitPath <$> lift getWorkingDirectory
    file <- validateDirectory cwd
    lift $ lines <$> readFile file
    where
        fullGitPath :: FilePath -> FilePath
        fullGitPath cwd = cwd  <> "/" <> ".gitignore"

allFilesInDir :: ExceptTDirecetory [FilePath]
allFilesInDir = (getFilesInDir <=< validateDirectory) =<< lift getWorkingDirectory

getFilesInDir :: FilePath -> ExceptTDirecetory [FilePath]
getFilesInDir = readEnitreDirStream [ ] <=<  lift . openDirStream <=<  validateDirectory


readEnitreDirStream :: [FilePath] -> DirStream -> ExceptTDirecetory [FilePath]
readEnitreDirStream lst ds = do
    dirStream <- lift . readDirStreamMaybe $ ds
    case dirStream of
        Nothing  -> throwE DirStreamFeil
        (Just d) -> actOnFilePath d
    where
        actOnFilePath :: FilePath -> ExceptTDirecetory [FilePath]
        actOnFilePath (null -> True) = lift (closeDirStream  ds) >> pure lst
        actOnFilePath file           = readEnitreDirStream (file:lst) ds



validateDirectory :: FilePath -> ExceptTDirecetory FilePath
validateDirectory fp = do
    exists <- lift $ fileExist fp
    unless exists (throwE FantIkkeFilen)

    isDir  <- lift $ isDirectory <$> getFileStatus fp
    unless isDir  (throwE IkkeEnDir)
    pure fp




















