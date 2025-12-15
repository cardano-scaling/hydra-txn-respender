{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # For cardano-cli to sign transactions
    cardano-node.url = "github:IntersectMBO/cardano-node/10.5.3";
    unison-nix = {
      url = "github:ceedubs/unison-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, unison-nix, cardano-node }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system}. appendOverlays [
          unison-nix.overlays.default
        ];
      in rec
      {
        packages.default = pkgs.unison.lib.buildFromTranscript {
          pname = "respend-utxo";
          version = "0.0.1";
          compiledHash = "sha256-bLth+kO2AG3v3GxpP1pPVv+ZXMqelm36tco9ILg1DSY=";
          src = ./transaction-respender.md;
        };

        apps.default = flake-utils.lib.mkApp { drv = packages.default; };

        devShells = {
          default = pkgs.mkShell {
            packages = with pkgs; [
              cardano-node.packages.${system}.cardano-cli
              unison-nix.packages.${system}.ucm-bin
            ];
          };
        };
      }
    );

  nixConfig = {
    extra-substituters = [
      "https://cache.iog.io"
      "https://cardano-scaling.cachix.org"
    ];
    extra-trusted-public-keys = [
      "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
      "cardano-scaling.cachix.org-1:QNK4nFrowZ/aIJMCBsE35m+O70fV6eewsBNdQnCSMKA="
    ];
    allow-import-from-derivation = true;
  };
}

