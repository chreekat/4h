#!/usr/bin/env bash
# Regenerates the committed cabal2nix output under nix/.
#
# With no argument the ghc-lib-parser pin is refreshed at its current version;
# pass a version to move it. That version is the Haskell dialect 4h formats, so
# move it together with the bound in 4h.cabal.
set -euo pipefail

root=$(git rev-parse --show-toplevel)
cd "$root"

ver=${1:-$(sed -n 's/^  version = "\(.*\)";$/\1/p' nix/ghc-lib-parser.nix | head -1)}
if [ -z "$ver" ]; then
    echo "could not determine the ghc-lib-parser version to pin" >&2
    exit 1
fi

cabal2nix "cabal://ghc-lib-parser-$ver" > nix/ghc-lib-parser.nix

# Two edits to cabal2nix's output for this package: the test suite's
# build-tool-depends on 4h itself becomes an argument named "4h", which is not a
# legal Nix identifier, and the source has to be filtered by the caller rather
# than taken as the whole working tree.
cabal2nix ./. \
    | sed -e 's/^{ mkDerivation, 4h, /{ mkDerivation, src, /' \
          -e 's/^  src = \.\/\.;$/  inherit src;/' \
          -e 's/^  testToolDepends = \[ 4h hspec-discover \];$/  testToolDepends = [ hspec-discover ];/' \
    > nix/4h.nix

# The edits above are textual, so check they landed rather than let a reflowed
# cabal2nix output through: an unfiltered src silently copies the whole tree.
fail=
grep -qx '  inherit src;' nix/4h.nix || fail="src is not taken from the caller"
grep -q '^{ mkDerivation, 4h,' nix/4h.nix && fail="the 4h argument survived"
grep -q '\[ 4h ' nix/4h.nix && fail="the self-referential 4h dependency survived"
if [ -n "$fail" ]; then
    echo "nix/4h.nix: $fail; cabal2nix output shape has changed" >&2
    exit 1
fi
