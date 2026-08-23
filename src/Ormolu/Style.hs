-- | The one formatting style 4h implements.
--
-- 4h is Ormolu with a fixed set of deviations and no way to change them, so
-- this module is the whole of its configuration surface: the vocabulary of
-- style decisions the printer speaks, and the single value fixing each one.
module Ormolu.Style (
    PrinterOpts (..),
    printerOpts,
    CommaStyle (..),
    RecordStyle (..),
    FunctionArrowsStyle (..),
    HaddockPrintStyle (..),
    HaddockPrintStyleModule (..),
    HaddockLocSignature (..),
    ImportExportStyle (..),
    LetStyle (..),
    InStyle (..),
    IfStyle (..),
    Unicode (..),
    SingleConstraintParens (..),
    ColumnLimit (..),
    SingleDerivingParens (..),
    ImportGrouping (..),
) where

-- | The style decisions the printer consults.
data PrinterOpts = PrinterOpts
    { poIndentation :: Int
    -- ^ Number of spaces per indentation step
    , poColumnLimit :: ColumnLimit
    -- ^ Max line length for automatic line breaking
    , poFunctionArrows :: FunctionArrowsStyle
    -- ^ Styling of arrows in type signatures
    , poCommaStyle :: CommaStyle
    -- ^ How to place commas in multi-line lists, records, etc.
    , poRecordStyle :: RecordStyle
    -- ^ How to place braces in records
    , poImportExportStyle :: ImportExportStyle
    -- ^ Styling of import/export lists
    , poImportGrouping :: ImportGrouping
    -- ^ Rules for grouping import declarations
    , poIndentWheres :: Bool
    -- ^ Whether to full-indent or half-indent 'where' bindings past the
    -- preceding body
    , poRecordBraceSpace :: Bool
    -- ^ Whether to leave a space before an opening record brace
    , poNewlinesBetweenDecls :: Int
    -- ^ Number of blank lines between top-level declarations
    , poHaddockStyle :: HaddockPrintStyle
    -- ^ How to print Haddock comments
    , poHaddockStyleModule :: HaddockPrintStyleModule
    -- ^ How to print the module docstring
    , poHaddockLocSignature :: HaddockLocSignature
    -- ^ Where to put docstring comments in function signatures
    , poLetStyle :: LetStyle
    -- ^ Styling of let blocks
    , poInStyle :: InStyle
    -- ^ How to align the @in@ keyword with respect to the @let@ keyword
    , poIfStyle :: IfStyle
    -- ^ Styling of if-statements
    , poSingleConstraintParens :: SingleConstraintParens
    -- ^ Whether to put parentheses around a single constraint
    , poSingleDerivingParens :: SingleDerivingParens
    -- ^ Whether to put parentheses around a single deriving class
    , poSortConstraints :: Bool
    -- ^ Whether to sort constraints
    , poSortDerivedClasses :: Bool
    -- ^ Whether to sort derived classes
    , poSortDerivingClauses :: Bool
    -- ^ Whether to sort deriving clauses
    , poTrailingSectionOperators :: Bool
    -- ^ Whether to place section operators (those that are infixr 0, such as
    -- @$@) in trailing position, continuing the expression indented below
    , poUnicode :: Unicode
    -- ^ Output Unicode syntax
    , poRespectful :: Bool
    -- ^ Give the programmer more choice on where to insert blank lines
    }
    deriving (Eq, Show)

-- | 4h's style: Ormolu, indented by four, with the choices that keep a diff
-- small when a list, signature, constraint or deriving clause grows by one
-- entry. Every field not marked below holds Ormolu's value.
printerOpts :: PrinterOpts
printerOpts =
    PrinterOpts
        { -- Four. There is no other correct number.
          poIndentation = 4
        , poColumnLimit = NoLimit
        , -- A new argument appends a line rather than editing the previous one,
          -- which under trailing arrows has to grow a @->@.
          poFunctionArrows = LeadingArrows
        , -- A new element appends a line rather than editing the previous one,
          -- which under trailing commas has to grow a @,@.
          poCommaStyle = Leading
        , poRecordStyle = RecordStyleAligned
        , -- Leading commas, but the first entry shares the opening paren's line so
          -- the list does not cost two extra lines.
          poImportExportStyle = ImportExportDiffFriendly
        , poImportGrouping = ImportGroupLegacy
        , poIndentWheres = True
        , poRecordBraceSpace = True
        , poNewlinesBetweenDecls = 1
        , poHaddockStyle = HaddockSingleLine
        , poHaddockStyleModule = PrintStyleInherit
        , poHaddockLocSignature = HaddockLocSigAuto
        , poLetStyle = LetInline
        , poInStyle = InRightAlign
        , poIfStyle = IfIndented
        , -- Kept at Ormolu's value: @(Foo a)@ growing to @(Foo a, Bar b)@ touches
          -- less than @Foo a@ does.
          poSingleConstraintParens = ConstraintAlways
        , poSingleDerivingParens = DerivingAlways
        , -- A canonical order means an added entry lands in one place rather than
          -- wherever it was typed.
          poSortConstraints = True
        , poSortDerivedClasses = True
        , poSortDerivingClauses = True
        , poTrailingSectionOperators = True
        , poUnicode = UnicodeNever
        , poRespectful = False
        }

data CommaStyle
    = Leading
    | Trailing
    deriving (Bounded, Enum, Eq, Show)

data RecordStyle
    = RecordStyleAligned
    | RecordStyleKnr
    deriving (Bounded, Enum, Eq, Show)

data FunctionArrowsStyle
    = TrailingArrows
    | LeadingArrows
    | LeadingArgsArrows
    deriving (Bounded, Enum, Eq, Show)

data HaddockPrintStyle
    = HaddockSingleLine
    | HaddockMultiLine
    | HaddockMultiLineCompact
    deriving (Bounded, Enum, Eq, Show)

data HaddockPrintStyleModule
    = PrintStyleInherit
    | PrintStyleOverride HaddockPrintStyle
    deriving (Eq, Show)

data HaddockLocSignature
    = HaddockLocSigAuto
    | HaddockLocSigLeading
    | HaddockLocSigTrailing
    deriving (Bounded, Enum, Eq, Show)

data ImportExportStyle
    = ImportExportLeading
    | ImportExportTrailing
    | ImportExportDiffFriendly
    deriving (Bounded, Enum, Eq, Show)

data LetStyle
    = LetAuto
    | LetInline
    | LetNewline
    | LetMixed
    deriving (Bounded, Enum, Eq, Show)

data InStyle
    = InLeftAlign
    | InRightAlign
    | InNoSpace
    deriving (Bounded, Enum, Eq, Show)

data IfStyle
    = IfIndented
    | IfHanging
    deriving (Bounded, Enum, Eq, Show)

data Unicode
    = UnicodeDetect
    | UnicodeAlways
    | UnicodeNever
    deriving (Bounded, Enum, Eq, Show)

data SingleConstraintParens
    = ConstraintAuto
    | ConstraintAlways
    | ConstraintNever
    deriving (Bounded, Enum, Eq, Show)

data ColumnLimit
    = NoLimit
    | ColumnLimit Int
    deriving (Eq, Show)

data SingleDerivingParens
    = DerivingAuto
    | DerivingAlways
    | DerivingNever
    deriving (Bounded, Enum, Eq, Show)

data ImportGrouping
    = ImportGroupLegacy
    | ImportGroupPreserve
    | ImportGroupSingle
    | ImportGroupByScope
    | ImportGroupByQualified
    | ImportGroupByScopeThenQualified
    deriving (Bounded, Enum, Eq, Show)
