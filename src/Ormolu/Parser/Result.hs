-- | A type for the result of parsing.
module Ormolu.Parser.Result (
    SourceSnippet (..),
    ParseResult (..),
    inputComments,
) where

import Data.List (sortOn)
import Data.Maybe (maybeToList)
import Data.Text (Text)
import GHC.Data.EnumSet (EnumSet)
import GHC.Hs (GhcPs, HsModule)
import GHC.LanguageExtensions.Type
import GHC.Types.SrcLoc (getLoc)
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
    -- ^ Whether this is a regular module or a signature file
    , prStackHeader :: Maybe LComment
    -- ^ Stack header
    , prPragmas :: [([LComment], Pragma)]
    -- ^ Pragmas and the associated comments
    , prCommentStream :: CommentStream
    -- ^ Comment stream
    , prHaddockText :: HaddockText
    -- ^ Source text of the module's Haddocks, keyed by span
    , prExtensions :: EnumSet Extension
    -- ^ Enabled extensions
    , prModuleFixityMap :: ModuleFixityMap
    -- ^ Fixity map for operators
    , prIndent :: Int
    -- ^ Indentation level; can be non-zero in the case of region formatting
    }

-- | All the comments a snippet started with, in source order.
--
-- This is not simply the comment stream: the Stack header and the comments
-- that precede pragmas are lifted out of the stream while parsing, and are
-- emitted separately. Haddocks, on the other hand, are not included at all,
-- because GHC's parser makes them part of the AST.
inputComments :: ParseResult -> [LComment]
inputComments ParseResult {prStackHeader, prPragmas, prCommentStream} =
    sortOn getLoc $
        maybeToList prStackHeader
            <> concatMap fst prPragmas
            <> streamComments
    where
        CommentStream streamComments = prCommentStream
