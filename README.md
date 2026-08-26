# 4h

[![License BSD3](https://img.shields.io/badge/license-BSD3-brightgreen.svg)](http://opensource.org/licenses/BSD-3-Clause)

* [The style](#the-style)
* [Installation](#installation)
* [Building from source](#building-from-source)
* [Usage](#usage)
    * [Editor integration](#editor-integration)
    * [Language extensions, dependencies, and fixities](#language-extensions-dependencies-and-fixities)
    * [Magic comments](#magic-comments)
    * [Regions](#regions)
    * [Exit codes](#exit-codes)
    * [Using as a library](#using-as-a-library)
* [Troubleshooting](#troubleshooting)
* [Limitations](#limitations)
* [Contributing](#contributing)
* [License](#license)

4h is a formatter for Haskell source code. It is a fork of
[Ormolu](https://github.com/tweag/ormolu) by way of
[Fourmolu](https://github.com/fourmolu/fourmolu), and it keeps Ormolu's
central promise:

> Implementing one “true” formatting style which admits no configuration.

There is no config file and there are no style flags. 4h differs from Ormolu
in exactly the ways listed below, and in no others.

## The style

4h indents by four, and takes the choices that keep a diff small when
something grows by one entry. That's the whole of it.

| | Ormolu | 4h |
|---|---|---|
| Indentation | 2 | **4** |
| Commas in lists, records, tuples | trailing | **leading** |
| Import and export lists | trailing commas | **diff-friendly** |
| Arrows in type signatures | trailing | **leading** |
| Constraints | source order | **sorted** |
| Derived classes | source order | **sorted** |
| Deriving clauses | source order | **sorted** |

Four spaces is the reason this fork exists. The rest earns its place by
making diffs smaller:

```haskell
-- Ormolu: adding `c` edits the `b` line too.
f ::
  Int ->
  Int ->
  Int
f = ...

-- 4h: adding `c` appends a line and touches nothing else.
f
    :: Int
    -> Int
    -> Int
f = ...
```

Sorting constraints and derived classes is the same idea one level up: a new
entry lands in one determined place instead of wherever it happened to be
typed, so two people adding the same constraint produce the same diff.

Note what is *not* on the list. Single constraints and single deriving
clauses keep Ormolu's parentheses — `(Show a) => ...`, not `Show a => ...` —
because `(Show a)` growing into `(Show a, Eq b)` touches less than `Show a`
does. Everything else, including `where` indentation, record brace spacing,
Haddock comment style, and blank-line handling, is Ormolu's behaviour
untouched.

## Installation

### Install with Cabal/Stack

```bash
cabal install 4h
stack install 4h
```

## Building from source

```console
$ cabal build -fdev
$ stack build --flag 4h:dev
```

The `dev` flag may be omitted in your local workflow as you work, but CI may
not pass if you only build without the `dev` flag.

## Usage

The following will print the formatted output to the standard output.

```console
$ 4h Module.hs
```

Add `-i` (or `--mode inplace`) to replace the contents of the input file with
the formatted output.

```console
$ 4h -i Module.hs
```

Specify a directory to recursively process all of its `.hs` files:

```console
$ 4h -i src
```

Or find all files in a project with `git ls-files`:

```bash
$ 4h --mode inplace $(git ls-files '*.hs')
# Or to avoid hitting command line length limits and enable parallelism (12-way here):
$ git ls-files -z '*.hs' | xargs -P 12 -0 4h --mode inplace
```

To check if files are already formatted (useful on CI):

```console
$ 4h --mode check src
```

#### :zap: Beware git's `core.autocrlf` on Windows :zap:
4h's output always uses LF line endings. In particular, `4h --mode check`
will fail if its input is correctly formatted *except* that it has CRLF line
endings. This situation can happen on Windows when checking out a git
repository without having set [`core.autocrlf`](
https://www.git-scm.com/docs/git-config#Documentation/git-config.txt-coreautocrlf)
to `false`.

### Editor integration

4h can be integrated with your editor via the [Haskell Language
Server](https://haskell-language-server.readthedocs.io/en/latest/index.html)
by pointing `haskell.formattingProvider` at the executable.

### Language extensions, dependencies, and fixities

4h automatically locates the Cabal file that corresponds to a given source
code file. Cabal files are used to extract both default extensions and
dependencies. Default extensions directly affect behavior of the GHC parser,
while dependencies are used to figure out fixities of operators that appear
in the source code. When the input comes from stdin, one can pass
`--stdin-input-file` which will give 4h the location that should be used as
the starting point for searching for `.cabal` files.

Fixities can also be overridden in a `.ormolu` file, which 4h looks for in
the directory of the source file and its ancestors. Here is an example:

```
infixr 9  .
infixr 5  ++
infixl 4  <$
infixl 1  >>, >>=
infixr 1  =<<
infixr 0  $, $!
infixl 4 <*>, <*, *>, <**>
infixr 3 >~<
infixr 3.3 |~|
infixr 3.7 <~>
```

It uses exactly the same syntax as usual Haskell fixity declarations to make
it easier for Haskellers to edit and maintain. Fractional precedences are
supported for more precise control over formatting of complex operator
chains.

A `.ormolu` file can also contain instructions about module re-exports that
4h should be aware of. This might be desirable because at the moment 4h
cannot know about all possible module re-exports in the ecosystem and only
few of them are actually important when it comes to fixity deduction. In 99%
of cases the user won't have to do anything, especially since most common
re-exports are already programmed in. However, when the fixity of an operator
is not inferred correctly, declaring a re-export may come in handy. Here is
an example:

```
module Control.Lens exports Control.Lens.At
module Control.Lens exports "lens" Control.Lens.Lens
```

Explicit package names are allowed in re-export declarations (see the example
above).

Finally, all of the above-mentioned parameters can be controlled from the
command line:

* Language extensions can be specified with the `-o` or `--ghc-opt` flag.
* Dependencies can be specified with the `-p` or `--package` flag.
* Fixities can be specified with the `-f` or `--fixity` flag.
* Re-exports can be specified with the `-r` or `--reexport` flag.

Searching for `.cabal` files can be disabled by passing `--no-cabal`, and
searching for `.ormolu` files by passing `--no-dot-ormolu`.

### Magic comments

4h understands two magic comments:

```haskell
{- FOURMOLU_DISABLE -}
```

and

```haskell
{- FOURMOLU_ENABLE -}
```

This allows us to disable formatting selectively for code between these
markers or disable it for the entire file. To achieve the latter, just put
`{- FOURMOLU_DISABLE -}` at the very top. Note that for 4h to work the
fragments where 4h is enabled must be parseable on their own. Because of that
the magic comments cannot be placed arbitrarily, but rather must enclose
independent top-level definitions.

`{- ORMOLU_DISABLE -}` and `{- ORMOLU_ENABLE -}`, respectively, can be used to
the same effect, and the two styles of magic comments can be mixed.

### Regions

One can ask 4h to format a region of input and leave the rest unformatted.
This is accomplished by passing the `--start-line` and `--end-line` command
line options. `--start-line` defaults to the beginning of the file, while
`--end-line` defaults to the end.

Note that the selected region needs to be parseable Haskell code on its own.

### Exit codes

Exit code | Meaning
----------|-----------------------------------------------
0         | Success
1         | General problem
2         | CPP used (deprecated)
3         | Parsing of original input failed
4         | Parsing of formatted code failed
5         | AST of original and formatted code differs
6         | Formatting is not idempotent
7         | Unrecognized GHC options
8         | Cabal file parsing failed
9         | Missing input file path when using stdin input and accounting for .cabal files
10        | Parse error while parsing fixity overrides
100       | In checking mode: unformatted files
101       | Inplace mode does not work with stdin
102       | Other issue (with multiple input files)

### Using as a library

The `4h` package can also be depended upon from other Haskell programs. For
these purposes only the top `Ormolu` module should be considered stable. Rely
on other modules at your own risk.

## Troubleshooting

### Operators are being formatted weirdly!

This can happen when 4h doesn't know or can't determine the fixity of an
operator.

* If this is a custom operator, see the instructions in the [Language
  extensions, dependencies, and
  fixities](#language-extensions-dependencies-and-fixities) section to
  specify the correct fixities in a `.ormolu` file.

* If this is a third-party operator (e.g. from `base` or some other package
  from Hackage), 4h probably doesn't recognize that the operator is the same
  as the third-party one.

  Some reasons this might be the case:

    * You might have a custom Prelude that re-exports things from Prelude
    * You might have `-XNoImplicitPrelude` turned on

  If any of these are true, make sure to specify the reexports correctly in a
  `.ormolu` file.

You can see how 4h decides the fixity of operators if you use `--debug`.

## Limitations

* CPP support is experimental. CPP is virtually impossible to handle
  correctly, so we process them as a sort of unchangeable snippets. This
  works only in simple cases when CPP conditionals surround top-level
  declarations. See the [CPP](https://github.com/tweag/ormolu/blob/master/DESIGN.md#cpp) section in the design notes for a
  discussion of the dangers.
* Various minor idempotence issues, most of them are related to comments.

## Contributing

New style options are out of scope: 4h admits no configuration, and the set
of deviations from Ormolu above is meant to stay closed. Bug reports and
fixes are very welcome.

See `DEVELOPER.md` for documentation.

## License

See [LICENSE.md](LICENSE.md).

Copyright © 2018–2020 Tweag I/O, 2020-present Matt Parsons

## Acknowledgements

The vast majority of the work here was done by the Ormolu and Fourmolu
developers, who deserve essentially all of the credit. 4h is Ormolu's style
with Fourmolu's printer, pinned to one set of choices.
