{
  description = "nvim-treesitter nightly overlay";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nvim-treesitter = {
      url = "github:nvim-treesitter/nvim-treesitter";
      flake = false;
    };
  };

  outputs =
    { ... }@inputs:
    let
      forAllSystems =
        function:
        inputs.nixpkgs.lib.genAttrs
          [
            "x86_64-linux"
            "aarch64-linux"
            "aarch64-darwin"
          ]
          (
            system:
            function (
              import inputs.nixpkgs {
                inherit system;
              }
            )
          );
    in
    {
      overlays = {
        default = (import ./overlay.nix { inherit inputs; });
      };

      devShells = forAllSystems (
        { pkgs, ... }:
        {
          default = pkgs.mkShell {
            packages = [
              (import ./generate-parsers { inherit inputs pkgs; })
            ];
          };
        }
      );

      packages = forAllSystems (
        { pkgs, ... }:
        let
          pkgs' = import inputs.nixpkgs {
            inherit (pkgs.stdenv.hostPlatform) system;
            overlays = (pkgs.overlays or [ ]) ++ [
              (import ./overlay.nix { inherit inputs; })
            ];
          };
        in
        rec {
          nvim-treesitter-unwrapped = pkgs'.vimPlugins.nvim-treesitter-unwrapped;
          nvim-treesitter = pkgs'.vimPlugins.nvim-treesitter;
          default = nvim-treesitter;
        }
      );

      formatter = forAllSystems (pkgs: pkgs.nixfmt);
    };
}
