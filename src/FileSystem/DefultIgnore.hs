module DefultIgnore where
import System.Posix.Directory.Internals (DirStream(..))
import System.Posix (getWorkingDirectory, openDirStream, readDirStream, fileExist, getFileStatus, isDirectory)

allFileInGitIgnore :: IO (Maybe [FilePath])
allFileInGitIgnore = do
    path   <- fullGitPath       <$> getWorkingDirectory
    notDir <- not . isDirectory <$> getFileStatus path
    exist  <- fileExist path 
    if exist &&  notDir   
    then pure . lines <$> readFile path
    else pure Nothing
    where
        fullGitPath cwd = cwd  <> "/" <> ".gitignore"


allFilesInDir :: IO [FilePath]
allFilesInDir =  getWorkingDirectory >>= getFilesInDir

getFilesInDir :: FilePath -> IO [FilePath]
getFilesInDir fp  = openDirStream fp >>= readEnitreDirStream []

readEnitreDirStream :: [FilePath] -> DirStream -> IO [FilePath]
readEnitreDirStream lst ds = do
    file <- readDirStream ds
    if null file
    then pure lst
    else readEnitreDirStream (file : lst ) ds
























