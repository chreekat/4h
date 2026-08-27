{-# LANGUAGE DataKinds #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE RecordWildCards #-}

-- | Pretty-printer for Haskell AST.
--
-- Each snippet is rendered twice. Comments are attached to the elements the
-- printer enters, and the only way to know which elements those are is to
-- render once and see; the first pass therefore runs with no comments at
-- all and is kept only for the spans it visited. See 'render'.
module Ormolu.Printer (
    printSnippets,
    printSnippetsWithPlacements,
) where

import Data.Choice (Choice)
import Data.Text (Text)
import Data.Text qualified as T
import GHC.Types.SrcLoc (RealSrcSpan)
import Ormolu.Comments.Anchor
import Ormolu.Parser.CommentStream (CommentStream (..))
import Ormolu.Parser.Result
import Ormolu.Printer.Combinators
import Ormolu.Printer.CommentPlacement
import Ormolu.Printer.Meat.Module
import Ormolu.Processing.Common

-- | Render several source snippets.
printSnippets
    :: Choice "debug"
    -- ^ Whether to print out debug information during printing
    -> [SourceSnippet]
    -- ^ Result of parsing
    -> Text
    -- ^ Resulting rendition
printSnippets debug = T.concat . fmap (\(t, _, _) -> t) . printSnippetsWithPlacements debug

-- | Like 'printSnippets', but also return, for each snippet, the placement
-- of every comment it emitted.
--
-- Snippets are rendered separately and their spans are relative to
-- themselves, so the placements stay grouped by snippet: anything that
-- compares them against the input has to work one snippet at a time.
printSnippetsWithPlacements
    :: Choice "debug"
    -- ^ Whether to print out debug information during printing
    -> [SourceSnippet]
    -- ^ Result of parsing
    -> [(Text, [CommentPlacement], [RealSrcSpan])]
    -- ^ For each snippet, its rendition, the comments it emitted, and the
    -- spans of the elements it emitted out of input order
printSnippetsWithPlacements debug = fmap (renderSnippet debug)

-- | Render one snippet. A snippet that could not be parsed is passed
-- through as it was.
renderSnippet
    :: Choice "debug"
    -> SourceSnippet
    -> (Text, [CommentPlacement], [RealSrcSpan])
renderSnippet debug = \case
    ParsedSnippet r -> render debug r
    RawSnippet r -> (r, [], [])

-- | Render one parsed snippet, along with the placement of every comment it
-- emitted.
--
-- This renders twice. Anchoring a comment to an element the printer never
-- enters would leave the comment stranded, and there is no way to know
-- which elements those are but to render once and see. The first pass is
-- given an empty 'AnchorMap', so it emits no comments and its output is
-- thrown away; what it is for is the spans it visited, which is what the
-- second pass attaches the comments to.
render
    :: Choice "debug"
    -> ParseResult
    -> (Text, [CommentPlacement], [RealSrcSpan])
render debug r@ParseResult {..} =
    let (_, _, visited, _) = renderWith noComments
        (rendered, placements, _, reordered) = renderWith (anchorMapFor r visited)
     in (rendered, placements, reordered)
    where
        renderWith anchorMap =
            let (rendered, placements, visited, reordered) =
                    runR
                        ( p_hsModule
                            prStackHeader
                            prPragmas
                            prParsedSource
                        )
                        anchorMap
                        prSourceType
                        prExtensions
                        prModuleFixityMap
                        debug
                        prHaddockText
             in (reindent prIndent rendered, placements, visited, reordered)

-- | Attach the comments of a snippet to the elements the printer enters.
anchorMapFor :: ParseResult -> [RealSrcSpan] -> AnchorMap
anchorMapFor ParseResult {..} visited =
    mkAnchorMap (attachComments comments visited)
    where
        CommentStream comments = prCommentStream
