module FileSystem.DefultIgnore where

import System.Posix.Directory.Internals (
    DirStream(..)
    )

import System.Posix (
      getWorkingDirectory
    , openDirStream
    , readDirStream
    , fileExist
    , getFileStatus
    , isDirectory
    )


getUnwatedFiles :: IO [FilePath]
getUnwatedFiles =  filterUnwantedGitignoreFiles unwantedFiles <$> allFileInGitIgnore  

unwantedFiles :: [FilePath] 
unwantedFiles = [",",""," "]

filterUnwantedGitignoreFiles :: [FilePath] -> [FilePath] -> [FilePath]
filterUnwantedGitignoreFiles unwf = filter pre
    where
    pre :: FilePath -> Bool
    pre =  flip notElem unwf 

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
