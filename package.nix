{ haskell, haskellPackages, nix-gitignore }:

let
  withTests = haskellPackages.callPackage ./nix/4h.nix {
    src = nix-gitignore.gitignoreSource [ ] ./.;
  };
in
haskell.lib.overrideCabal
  (haskell.lib.justStaticExecutables (haskell.lib.dontCheck withTests))
  (drv: {
    passthru = (drv.passthru or { }) // { inherit withTests; };
  })
