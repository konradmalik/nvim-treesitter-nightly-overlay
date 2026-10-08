{
  description = "nvim-treesitter nightly overlay";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nvim-treesitter = {
      url = "github:nvim-treesitter/nvim-treesitter";
      flake = false;
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { ... }@inputs:
    let
      overlay = import ./overlay.nix { inherit inputs; };

      forAllSystems =
        function:
        inputs.nixpkgs.lib.genAttrs [
          "x86_64-linux"
          "aarch64-linux"
          "aarch64-darwin"
        ] (system: function inputs.nixpkgs.legacyPackages.${system});

      treefmtFor = pkgs: inputs.treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
    in
    {
      overlays = {
        default = overlay;
      };

      devShells = forAllSystems (
        pkgs:
        let
          treefmt = (treefmtFor pkgs).config.build;
        in
        {
          default = pkgs.mkShellNoCC {
            packages = [
              treefmt.wrapper
              (import ./generate-parsers { inherit inputs pkgs; })
            ]
            ++ builtins.attrValues treefmt.programs;
          };
        }
      );

      packages = forAllSystems (
        pkgs:
        let
          pkgs' = pkgs.extend overlay;
        in
        rec {
          nvim-treesitter = pkgs'.vimPlugins.nvim-treesitter;
          default = nvim-treesitter;
        }
      );

      checks = forAllSystems (pkgs: {
        formatting = (treefmtFor pkgs).config.build.check inputs.self;
      });

      formatter = forAllSystems (pkgs: (treefmtFor pkgs).config.build.wrapper);
    };
}
