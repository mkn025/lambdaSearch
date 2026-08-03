module FileSystem.Search (
       treverseDirWithSettings
     , unpackAbsolutPath 
     , unpackRelativPath 
     )
    where 

import Core.TraversalTypes (
      AbsolutPath    (..)
    , RelativPath    (..)
    , FilePaths      (..)
    , DirContent     (..)
    , FileInfomation (..)
    )

import Core.SettingsTypes  (
      SearchSetting(..)
    , Arguments
    , ConstrucedCommand 
    )                          

-- Filter And helpers --
import Core.Filters (
      getDisallowFilter
    , getHiddenFilter
    , getExtentionFilter
    , compileRegexFilter
    , getRexPattern
    , executeFunction
    , substituePath
    , convertToString
    , convertString
    )


import FileSystem.RawFilePathUtils (
      concatRelativeFilePath
    , createFileInformation
    , dtDir
    , unpackAbsolutPath
    , unpackRelativPath
    )
import FileSystem.Raw (foldDirectoryTree)


import System.Posix.ByteString.FilePath  (RawFilePath)
import System.Process                    (createProcess, proc, waitForProcess)
import System.Exit                       (ExitCode (..))
import System.Posix.Directory.ByteString (getWorkingDirectory)




-- | Rekkursiv traversering med aktive filter
--  Går igjennom alle filene og rekusrsivt. Og akkumlerer ønskete filer i acc listen vår
treversRecursively:: Arguments -> [FileInfomation] -> FilePaths -> IO [FileInfomation]
treversRecursively args = foldDirectoryTree foldFunc
    where
    regexCompiled = compileRegexFilter args
    foldFunc :: [FileInfomation] -> FilePaths -> DirContent -> IO [FileInfomation]

    foldFunc acc filePaths dc@DirContent{..}  = do

        let relFilePath = concatRelativeFilePath  (relativeFilePath filePaths) (pure name) (Just dc)
        let fullPath    = absoluteFilePath filePaths <> pure name

        let paths       = FilePaths{ absoluteFilePath = fullPath, relativeFilePath = relFilePath }
        let isDir       = fileType == dtDir

        if isDir
            then pure $ createFileInformation paths Nothing : acc
            else do
                let rg  = getRexPattern      regexCompiled name
                let hf  = getHiddenFilter    args name
                let ef  = getExtentionFilter args name
                let df  = getDisallowFilter  args (unpackAbsolutPath . absoluteFilePath $ filePaths )
                if and [rg, ef, hf, df]
                then do
                    executeFunction args (unpackAbsolutPath . absoluteFilePath $ filePaths ) executeOnFile
                    pure $ createFileInformation paths{absoluteFilePath = absoluteFilePath filePaths } (Just dc) : acc -- absoluteFilePath filePaths = old filepath
                else pure acc






-- | Kjører en kommando på på en filen vår 
--  Vente på om den. Gir tom tupel om good. Eller gir ioError  ellers
executeOnFile :: ConstrucedCommand -> RawFilePath ->  IO ()
executeOnFile c@(prog, args) rfd = do
                                let argsWithPath = substituePath args rfd
                                (_, _, _, ph) <- createProcess $ proc prog argsWithPath
                                ec <- waitForProcess ph
                                case ec of
                                    ExitSuccess   -> pure ()
                                    ExitFailure n -> ioError $ userError (
                                           "Command failed: "
                                        <> show c
                                        <> " (exit " ++ show n ++ ")"    )



-- | Treveser med søkinstillinger
treverseDirWithSettings  :: SearchSetting -> IO [FileInfomation]
treverseDirWithSettings  = liftA2 treveseManyPathsWithArgs arguments searchPaths 


-- | Treverser med argumter, standardsti velges når ingen søkestier er oppgitt.
--  Treverser med mange i cwd dersom du ikke gir noe dir
treveseManyPathsWithArgs  :: Arguments ->  Maybe [FilePath]  -> IO [FileInfomation]
treveseManyPathsWithArgs ff Nothing   = getWorkingDirectory  >>= treverseOnPathWithArgs ff . convertToString
treveseManyPathsWithArgs ff (Just fp) = concat <$> mapM (treverseOnPathWithArgs ff) fp


-- | Treveser en filsti
--  difinere hvordan vi skal jobbe på en filepath. Slik at vi etterpå kan mapM på en liste med filepath
treverseOnPathWithArgs :: Arguments -> FilePath -> IO [FileInfomation]
treverseOnPathWithArgs ff sp = treversRecursively ff [] paths
    where
    paths = FilePaths {absoluteFilePath  = absStartPath , relativeFilePath  = relStartPath }
    absStartPath = AbsolutPath .  convertString  $ sp
    relStartPath = RelativPath ""






