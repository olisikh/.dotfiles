{ pkgs, nixvimLib, ... }:
import ./plugins/blink-cmp.nix { inherit nixvimLib; } //
import ./plugins/dap.nix { inherit pkgs nixvimLib; } //
import ./plugins/gitsigns.nix //
import ./plugins/lsp.nix //
import ./plugins/lint.nix //
import ./plugins/conform-nvim.nix //
import ./plugins/lualine.nix //
import ./plugins/markdown-preview.nix //
import ./plugins/neotest.nix { inherit pkgs nixvimLib; } //
import ./plugins/none-ls.nix //
import ./plugins/nvim-tree.nix { inherit nixvimLib; } //
import ./plugins/telescope.nix //
import ./plugins/treesitter.nix { inherit pkgs; } //
import ./plugins/undotree.nix //
import ./plugins/rustaceanvim.nix { inherit pkgs; } //
import ./plugins/which-key.nix //
import ./plugins/copilot-lua.nix //
import ./plugins/todo-comments.nix //
import ./plugins/colorizer.nix //
import ./plugins/codecompanion.nix { inherit nixvimLib; } //
import ./plugins/avante.nix { inherit nixvimLib; } //
import ./plugins/obsidian.nix { inherit nixvimLib; } //
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
  helm.enable = true;
  crates.enable = true;
  fidget.enable = true;
  nvim-surround.enable = true;
  lazygit.enable = true;
}
