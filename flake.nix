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
            rev = "78b358bb5794706714643e30ec961122d99443c0";
            sha256 = "sha256-2LTWlueh2ZB7y8eVrD+aeF9ERNmFQONBLy1b9KRHaVY=";
          };

          npmDepsHash = "sha256-efXXOVihiiiDYJamIU0EiX2I+RgOAkjKK8DF3KQtw3k=";
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
          ];
        };
      }
    );
}
