# Handoff: Nix Build SSL Fix for Codeberg-Hosted Neovim Plugins

**Date**: 2026-06-01  
**Workspace**: `/Users/olisikh/.dotfiles`  
**Status**: COMPLETE — build succeeds as of end of session

---

## What Was Fixed

`dots make` (nix-darwin rebuild) was failing because several Neovim plugins hosted on **codeberg.org** could not be fetched during the Nix build. Root cause: the Netskope corporate SSL inspection proxy intercepts HTTPS, re-signs with its own CA, and the Nix build sandbox's `fetchgit` (git clone) does not receive the `ssl-cert-file` configured in `/etc/nix/nix.conf`. curl-based fetchers (`fetchFromGitHub`, `fetchzip`) do work through the proxy.

---

## Files Changed

### `overlays/nvim-plugins-overlay/default.nix`

Added 5 new plugin overrides using `buildVimPlugin` + `fetchFromGitHub` (tarball, not git clone) to bypass the SSL issue:

- `nvim-dap` — from `mfussenegger/nvim-dap` on GitHub
- `nvim-dap-ui` — from `rcarriga/nvim-dap-ui`, with `dependencies = with final.vimPlugins; [ nvim-dap nvim-nio ]`
- `nvim-dap-virtual-text` — from `theHamsta/nvim-dap-virtual-text`, with `dependencies = with final.vimPlugins; [ nvim-dap nvim-treesitter ]`
- `nvim-dap-python` — from `mfussenegger/nvim-dap-python`
- `nvim-lint` — **currently commented out** (see status note below)

Key insight: `nvim-dap-ui` and `nvim-dap-virtual-text` must also be overridden because nixpkgs bakes the old codeberg-fetched `nvim-dap` into their derivations as `buildInputs` — overriding `nvim-dap` alone does not fix their closures.

### `modules/home/dev/shell/nixvim/plugins/dap.nix`

Added `package = pkgs.vimPlugins.<name>` to each DAP plugin so nixvim uses the overlaid packages instead of its internal defaults:

- `dap.package = pkgs.vimPlugins.nvim-dap`
- `dap-python.package = pkgs.vimPlugins.nvim-dap-python`
- `dap-ui.package = pkgs.vimPlugins.nvim-dap-ui`
- `dap-virtual-text.package = pkgs.vimPlugins.nvim-dap-virtual-text`

### `modules/home/dev/shell/nixvim/plugins/lint.nix`

- `lint.nix` does **NOT** yet have `pkgs` added to function args or `package = pkgs.vimPlugins.nvim-lint` set — the nvim-lint override in the overlay is still commented out.

---

## Current State of `nvim-lint`

The `nvim-lint` override in the overlay is commented out:

```nix
# nvim-lint = final.vimUtils.buildVimPlugin {
#   pname = "nvim-lint";
#   ...
# };
```

And `lint.nix` still reads `{ lib, ... }:` (no `pkgs` arg, no `package =` override).

This means the build currently succeeds likely because nixpkgs's `nvim-lint` **does not** use `fetchgit` from codeberg (it may already use GitHub or another source that works through the proxy), OR because this plugin isn't being fetched during builds (cached). If `nvim-lint` starts failing again, the fix is:

1. Uncomment the `nvim-lint` block in the overlay.
2. Add `pkgs` to `lint.nix` function args.
3. Add `package = pkgs.vimPlugins.nvim-lint;` to the `lint` plugin config.

---

## Architecture Notes

- **Flake framework**: [snowfall-lib](https://github.com/snowfallorg/lib) — overlays auto-discovered from `overlays/` directory
- **Overlay format**: `{ ... }: final: prev: { ... }` (extra arg for flake inputs)
- **nixvim**: used as `nixvim.homeModules.nixvim` in `homes.modules` inside `flake.nix`
- **`package =` is mandatory**: nixvim manages its own internal plugin packages. Without `package = pkgs.vimPlugins.<name>`, nixvim ignores the overlay for those plugins entirely.
- **Determinate Nix 3.21.0** (Nix 2.34.6) — `ssl-cert-file` in `/etc/nix/nix.conf` does NOT propagate `NIX_SSL_CERT_FILE` to `fetchgit` build sandboxes in this version.

---

## Suggested Next Steps

- Verify `nvim-lint` is truly working (check if it's codeberg-sourced in nixpkgs)
- Consider uncommenting `nvim-lint` in the overlay preemptively for consistency
- Commit the changes (currently unstaged on `main`)

---

## Suggested Skills

None specific required. Standard Nix/nix-darwin debugging skills apply. If the build fails again on other plugins, the pattern is:

1. Identify the failing `fetchgit` source URL
2. Find the GitHub equivalent
3. Add a `buildVimPlugin` + `fetchFromGitHub` override in the overlay
4. Add `package = pkgs.vimPlugins.<name>` in the corresponding nixvim plugin config
