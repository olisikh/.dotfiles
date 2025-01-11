{ pkgs, nixvimLib, ... }:

import ./blink-cmp.nix { inherit nixvimLib; } //
import ./dap.nix { inherit pkgs nixvimLib; } //
import ./gitsigns.nix //
import ./lsp.nix //
import ./lint.nix //
import ./conform-nvim.nix //
import ./lualine.nix //
import ./markdown-preview.nix //
import ./neotest.nix { inherit pkgs nixvimLib; } //
import ./none-ls.nix //
import ./nvim-tree.nix { inherit nixvimLib; } //
import ./telescope.nix //
import ./treesitter.nix { inherit pkgs; } //
import ./undotree.nix //
import ./rustaceanvim.nix { inherit pkgs; } //
import ./which-key.nix //
import ./copilot-lua.nix //
import ./todo-comments.nix //
import ./colorizer.nix //
import ./codecompanion.nix //
import ./obsidian.nix { inherit nixvimLib; } //
{
  lz-n.enable = true;
  web-devicons.enable = true;
  oil.enable = true;
  smart-splits.enable = true;
  nvim-autopairs.enable = true;
  trouble.enable = true;
  sleuth.enable = true;
  render-markdown.enable = true;
  hardtime.enable = true;
  luasnip.enable = true;
  helm.enable = true;
  crates.enable = true;
  fidget.enable = true;
  nvim-surround.enable = true;
}
