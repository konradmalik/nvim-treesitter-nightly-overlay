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
      overlay = import ./overlay.nix { inherit inputs; };

      forAllSystems =
        function:
        inputs.nixpkgs.lib.genAttrs
          [
            "x86_64-linux"
            "aarch64-linux"
            "aarch64-darwin"
          ]
          (system: function inputs.nixpkgs.legacyPackages.${system});
    in
    {
      overlays = {
        default = overlay;
      };

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [
            (import ./generate-parsers { inherit inputs pkgs; })
          ];
        };
      });

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

      formatter = forAllSystems (pkgs: pkgs.nixfmt);
    };
}
