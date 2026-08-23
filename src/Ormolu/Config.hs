{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE RecordWildCards #-}

-- | Configuration options used by the tool.
module Ormolu.Config (
    Config (..),
    ColorMode (..),
    RegionIndices (..),
    RegionDeltas (..),
    SourceType (..),
    defaultConfig,
    overapproximatedDependencies,
    regionIndicesToDeltas,
    DynOption (..),
    dynOptionToLocatedStr,
) where

import Data.Map.Strict qualified as Map
import Data.Set (Set)
import Data.Set qualified as Set
import Distribution.Types.PackageName (PackageName)
import GHC.Generics (Generic)
import GHC.Types.SrcLoc qualified as GHC
import Ormolu.Fixity
import Ormolu.Terminal (ColorMode (..))

-- | Type of sources that can be formatted by Ormolu.
data SourceType
    = -- | Consider the input as a regular Haskell module
      ModuleSource
    | -- | Consider the input as a Backpack module signature
      SignatureSource
    deriving (Eq, Show)

-- | Ormolu configuration.
data Config region = Config
    { cfgDynOptions :: ![DynOption]
    -- ^ Dynamic options to pass to GHC parser
    , cfgFixityOverrides :: !FixityOverrides
    -- ^ Fixity overrides
    , cfgModuleReexports :: !ModuleReexports
    -- ^ Module reexports to take into account when doing fixity resolution
    , cfgDependencies :: !(Set PackageName)
    -- ^ Known dependencies, if any
    , cfgUnsafe :: !Bool
    -- ^ Do formatting faster but without automatic detection of defects
    , cfgDebug :: !Bool
    -- ^ Output information useful for debugging
    , cfgCheckIdempotence :: !Bool
    -- ^ Checks if re-formatting the result is idempotent
    , cfgSourceType :: !SourceType
    -- ^ How to parse the input (regular haskell module or Backpack file)
    , cfgColorMode :: !ColorMode
    -- ^ Whether to use colors and other features of ANSI terminals
    , cfgRegion :: !region
    -- ^ Region selection
    }
    deriving (Eq, Functor, Generic, Show)

-- | Region selection as the combination of start and end line numbers.
data RegionIndices = RegionIndices
    { regionStartLine :: !(Maybe Int)
    -- ^ Start line of the region to format
    , regionEndLine :: !(Maybe Int)
    -- ^ End line of the region to format
    }
    deriving (Eq, Show)

-- | Region selection as the length of the literal prefix and the literal
-- suffix.
data RegionDeltas = RegionDeltas
    { regionPrefixLength :: !Int
    -- ^ Prefix length in number of lines
    , regionSuffixLength :: !Int
    -- ^ Suffix length in number of lines
    }
    deriving (Eq, Show)

-- | Default @'Config' 'RegionIndices'@.
defaultConfig :: Config RegionIndices
defaultConfig =
    Config
        { cfgDynOptions = []
        , cfgFixityOverrides = defaultFixityOverrides
        , cfgModuleReexports = defaultModuleReexports
        , cfgDependencies = Set.empty
        , cfgUnsafe = False
        , cfgDebug = False
        , cfgCheckIdempotence = False
        , cfgSourceType = ModuleSource
        , cfgColorMode = Auto
        , cfgRegion =
            RegionIndices
                { regionStartLine = Nothing
                , regionEndLine = Nothing
                }
        }

-- | Return all dependencies of the module. This includes both the declared
-- dependencies of the component we are working with and all potential
-- module re-export targets.
overapproximatedDependencies :: Config region -> Set PackageName
overapproximatedDependencies Config {..} =
    Set.union cfgDependencies potentialReexportTargets
    where
        potentialReexportTargets =
            Set.fromList
                . concatMap toTargetPackages
                $ Map.elems (unModuleReexports cfgModuleReexports)
        toTargetPackages = concatMap $ \case
            (Nothing, _) -> []
            (Just x, _) -> [x]

-- | Convert 'RegionIndices' into 'RegionDeltas'.
regionIndicesToDeltas
    :: Int
    -- ^ Total number of lines in the input
    -> RegionIndices
    -- ^ Region indices
    -> RegionDeltas
    -- ^ Region deltas
regionIndicesToDeltas total RegionIndices {..} =
    RegionDeltas
        { regionPrefixLength = maybe 0 (subtract 1) regionStartLine
        , regionSuffixLength = maybe 0 (total -) regionEndLine
        }

-- | A wrapper for dynamic options.
newtype DynOption = DynOption
    { unDynOption :: String
    }
    deriving (Eq, Ord, Show)

-- | Convert 'DynOption' to @'GHC.Located' 'String'@.
dynOptionToLocatedStr :: DynOption -> GHC.Located String
dynOptionToLocatedStr (DynOption o) = GHC.L GHC.noSrcSpan o
