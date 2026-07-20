<div align="center">
  <br/>
  <br/>
  <h1>nvim-treesitter-nightly-overlay</h1>
  <p><strong>A Nixpkgs overlay for the nightly nvim-treesitter plugin</strong></p>
  <div>
    <img
      alt="Build"
      src="https://img.shields.io/github/actions/workflow/status/konradmalik/nvim-treesitter-nightly-overlay/main.yaml?style=for-the-badge&logo=starship&color=8bd5ca&logoColor=D9E0EE&labelColor=302D41"
    />
    <img
      alt="License"
      src="https://img.shields.io/github/license/konradmalik/nvim-treesitter-nightly-overlay?style=for-the-badge&logo=starship&color=ee999f&logoColor=D9E0EE&labelColor=302D41"
    />
    <img
      alt="Stars"
      src="https://img.shields.io/github/stars/konradmalik/nvim-treesitter-nightly-overlay?style=for-the-badge&logo=starship&color=c69ff5&logoColor=D9E0EE&labelColor=302D41"
    />
  </div>
</div>

## Overview

**nvim-treesitter-nightly-overlay** is a flake that builds the up-to-date `main` branch `nvim-treesitter`, along with all of the parser versions from the [`parsers.lua`](https://github.com/nvim-treesitter/nvim-treesitter/blob/main/lua/nvim-treesitter/parsers.lua) file, as recommended by the project.

## Usage

**See below if you also plan to install tree-sitter grammars**

In your flake.nix:

```nix
    inputs = {
        nvim-treesitter-nightly.url = "github:konradmalik/nvim-treesitter-nightly-overlay";
    };
    # ... and import the overlay
    pkgs = import nixpkgs {
      inherit system;
      overlays = [
        inputs.nvim-treesitter-main.overlays.default
      ];
    };

```

## Parsers (withPlugins, withAllGrammars)

`nvim-treesitter` expects all of the parsers and queries to be installed in a single directory (in a non-nix setting this would be done imperatively via `:TSInstall` into `~/.local`). To pacify it in a nix setting, `withPlugins` and `withAllGrammars` have been extended to bundle all defined parsers into a single path, and patch the nvim-treesitter `config.lua` `install_dir` setting to point directly at the bundle in the nix store.

A few other neovim plugins define `nvim-treesitter` as a dependency, meaning we run the risk of having two separate copies of `nvim-treesitter` presented to Neovim which can cause issues because one copy will not be aware of your installed parsers. To fix, create an overlay like below to redefine `nvim-treesitter` and any dependent plugins in your nixpkgs set.

_If you are not using any other plugins that depend on `nvim-treesitter`, you may skip this step, but it's still recommended._

```nix
overlays = [
  inputs.nvim-treesitter-main.overlays.default
  (final: prev: {
    vimPlugins = prev.vimPlugins.extend (
      f: p: {
        nvim-treesitter = p.nvim-treesitter.withAllGrammars; # or withPlugins...
        # also redefine nvim-treesitter-textobjects (any other plugins that depend on nvim-treesitter)
        nvim-treesitter-textobjects = p.nvim-treesitter-textobjects.overrideAttrs {
          dependencies = [ f.nvim-treesitter ];
        };
      }
    );
  })
];
```

If you need the `nvim-treesitter` plugin without any parsers/queries bundled, use the `nvim-treesitter` output directly (i.e. without calling `.withAllGrammars`/`.withPlugins`) — the bundling only happens when you call those functions.

Because parsers live in the read-only nix store, the commands that would install/update/remove them at runtime (`:TSInstall`, `:TSInstallFromGrammar`, `:TSUpdate`, `:TSUninstall`) are removed. `:TSLog` is kept.

## Updating

To update the list of parsers in `generated.nix`:

```bash
nix flake update
nix develop --command "generate-parsers"
```

This runs a lua script similar to the old [update.py](https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/editors/vim/plugins/utils/nvim-treesitter/update.py), but uses the `nvim-treesitter` as a source for version info instead of the NURR json file.
