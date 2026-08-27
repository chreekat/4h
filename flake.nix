{
  description = "4h -- 4-space Haskell";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f:
        nixpkgs.lib.genAttrs systems (system: f (import nixpkgs { inherit system; }));

      haskellPackagesFor = pkgs:
        pkgs.haskell.packages.ghc9141.override {
          overrides = final: prev: {
            # Upstream needs Cabal-syntax 3.16, so we override.
            # Update with scripts/update-nix.sh
            ghc-lib-parser = final.callPackage ./nix/ghc-lib-parser.nix { };
          };
        };

      packageFor = pkgs:
        pkgs.callPackage ./package.nix {
          haskellPackages = haskellPackagesFor pkgs;
        };
    in
    {
      packages = forAllSystems (pkgs: {
        "4h" = packageFor pkgs;
        default = packageFor pkgs;
      });

      apps = forAllSystems (pkgs: {
        update-nix = {
          type = "app";
          program = nixpkgs.lib.getExe (pkgs.writeShellApplication {
            name = "update-nix";
            runtimeInputs = [ pkgs.cabal2nix pkgs.git pkgs.gnused ];
            text = builtins.readFile ./scripts/update-nix.sh;
          });
        };
      });

      devShells = forAllSystems (pkgs: {
        default = (haskellPackagesFor pkgs).shellFor {
          packages = p: [ (packageFor pkgs).withTests ];
          nativeBuildInputs = [
            pkgs.cabal-install
            pkgs.cabal2nix
          ];
        };
      });
    };
}
