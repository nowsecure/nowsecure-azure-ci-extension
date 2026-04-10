{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        tfx-cli = pkgs.buildNpmPackage {
          name = "tfx-cli";

          buildInputs = with pkgs; [
            nodejs_20
          ];

          src = pkgs.fetchFromGitHub {
            owner = "microsoft";
            repo = "tfs-cli";
            # Pinning to a commit sha because they appear not to use tags or releases
            rev = "530a65563483d86bd3b77d98c054ed0b44c47047";
            sha256 = "sha256-8sn0KXB0KnPlc33FXAPxJIQwi0T7XNAohsuq/aIjPyk=";
          };

          npmDepsHash = "sha256-1JZHdKN4IdEd92A/tBkD0nWWPjVFzOblQYCDwEAYx2s=";
        };
        nvmVersion =
          let
            inherit (builtins) head match readFile;
          in
          head (match "v?([[:digit:]]+).*" (readFile ./.nvmrc));
        node = "nodejs_${nvmVersion}";
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            tfx-cli
            pkgs.${node}
            pkgs.typescript
            # For linting tasks
            pkgs.jq
            pkgs.biome
            pkgs.markdownlint-cli
            pkgs.typos
            pkgs.actionlint
          ];
        };
      }
    );
}
