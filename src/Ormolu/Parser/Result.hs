-- | A type for result of parsing.
module Ormolu.Parser.Result (
    SourceSnippet (..),
    ParseResult (..),
) where

import Data.Text (Text)
import GHC.Data.EnumSet (EnumSet)
import GHC.Hs (GhcPs, HsModule)
import GHC.LanguageExtensions.Type
import Ormolu.Config (SourceType)
import Ormolu.Fixity (ModuleFixityMap)
import Ormolu.Parser.CommentStream
import Ormolu.Parser.Pragma (Pragma)

-- | Either a 'ParseResult', or a raw snippet.
data SourceSnippet = RawSnippet Text | ParsedSnippet ParseResult

-- | A collection of data that represents a parsed module in Ormolu.
data ParseResult = ParseResult
    { prParsedSource :: HsModule GhcPs
    -- ^ Parsed module or signature
    , prSourceType :: SourceType
    -- ^ Either regular module or signature file
    , prStackHeader :: Maybe LComment
    -- ^ Stack header
    , prPragmas :: [([LComment], Pragma)]
    -- ^ Pragmas and the associated comments
    , prCommentStream :: CommentStream
    -- ^ Comment stream
    , prExtensions :: EnumSet Extension
    -- ^ Enabled extensions
    , prModuleFixityMap :: ModuleFixityMap
    -- ^ Fixity map for operators
    , prIndent :: Int
    -- ^ Indentation level, can be non-zero in case of region formatting
    }
