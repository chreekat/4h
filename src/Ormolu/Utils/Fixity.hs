{-# LANGUAGE LambdaCase #-}

module Ormolu.Utils.Fixity (
    getDotOrmoluForSourceFile,
    parseFixityDeclarationStr,
    parseModuleReexportDeclarationStr,
) where

import Control.Exception (throwIO)
import Control.Monad.IO.Class
import Data.Bifunctor (first)
import Data.List.NonEmpty (NonEmpty)
import Data.Text qualified as T
import Data.Text.IO.Utf8 qualified as T.Utf8
import Distribution.ModuleName (ModuleName)
import Distribution.Types.PackageName (PackageName)
import Ormolu.Exception
import Ormolu.Fixity
import Ormolu.Fixity.Parser
import Ormolu.Utils.IO (Cache, findClosestFileSatisfying, newCache, withCache)
import System.Directory
import System.IO.Unsafe (unsafePerformIO)
import Text.Megaparsec (errorBundlePretty)

-- | Attempt to locate and parse an @.ormolu@ file. If it does not exist,
-- the default fixity map and module re-exports are returned. This function
-- maintains a cache of fixity overrides and module re-exports keyed by
-- @.ormolu@ file path.
getDotOrmoluForSourceFile
    :: (MonadIO m)
    => FilePath
    -- ^ 'CabalInfo' already obtained for this source file
    -> m (FixityOverrides, ModuleReexports)
getDotOrmoluForSourceFile sourceFile =
    liftIO (findDotOrmoluFile sourceFile) >>= \case
        Just dotOrmoluFile -> liftIO $ withCache cacheRef dotOrmoluFile $ do
            dotOrmoluRelative <- makeRelativeToCurrentDirectory dotOrmoluFile
            contents <- T.Utf8.readFile dotOrmoluFile
            case parseDotOrmolu dotOrmoluRelative contents of
                Left errorBundle ->
                    throwIO (OrmoluFixityOverridesParseError errorBundle)
                Right x -> return x
        Nothing -> return (defaultFixityOverrides, defaultModuleReexports)

-- | Find the path to an appropriate @.ormolu@ file for a Haskell source
-- file, if available.
findDotOrmoluFile
    :: (MonadIO m)
    => FilePath
    -- ^ Path to a Haskell source file
    -> m (Maybe FilePath)
    -- ^ Absolute path to the closest @.ormolu@ file, if available
findDotOrmoluFile = findClosestFileSatisfying $ \x ->
    x == ".ormolu"

-- | Cache ref that maps names of @.ormolu@ files to their contents.
cacheRef :: Cache FilePath (FixityOverrides, ModuleReexports)
cacheRef = unsafePerformIO newCache
{-# NOINLINE cacheRef #-}

-- | A wrapper around 'parseFixityDeclaration' for parsing individual fixity
-- definitions.
parseFixityDeclarationStr
    :: String
    -- ^ Input to parse
    -> Either String [(OpName, FixityInfo)]
    -- ^ Parse result
parseFixityDeclarationStr =
    first errorBundlePretty . parseFixityDeclaration . T.pack

-- | A wrapper around 'parseModuleReexportDeclaration' for parsing an
-- individual module re-export.
parseModuleReexportDeclarationStr
    :: String
    -- ^ Input to parse
    -> Either String (ModuleName, NonEmpty (Maybe PackageName, ModuleName))
    -- ^ Parse result
parseModuleReexportDeclarationStr =
    first errorBundlePretty . parseModuleReexportDeclaration . T.pack
