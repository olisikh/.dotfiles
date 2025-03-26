{ pkgs, nixvimLib, config, namespace, lib, ... }:
let
  # Helper function to import plugin with all common arguments
  importPlugin = file: import file {
    inherit pkgs nixvimLib config namespace lib;
  };
in
lib.foldl' (acc: plugin: acc // importPlugin plugin) {} [
  ./plugins/blink-cmp.nix
  ./plugins/dap.nix
  ./plugins/gitsigns.nix
  ./plugins/lsp.nix
  ./plugins/lint.nix
  ./plugins/conform-nvim.nix
  ./plugins/lualine.nix
  ./plugins/markdown-preview.nix
  ./plugins/neotest.nix
  ./plugins/none-ls.nix
  ./plugins/nvim-tree.nix
  ./plugins/telescope.nix
  ./plugins/treesitter.nix
  ./plugins/undotree.nix
  ./plugins/rustaceanvim.nix
  ./plugins/which-key.nix
  ./plugins/copilot-lua.nix
  ./plugins/todo-comments.nix
  ./plugins/colorizer.nix
  ./plugins/avante.nix
  ./plugins/obsidian.nix
  ./plugins/luasnip.nix
  ./plugins/aerial.nix
] //
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
  friendly-snippets.enable = true;
  helm.enable = true;
  crates.enable = true;
  fidget.enable = true;
  nvim-surround.enable = true;
  lazygit.enable = true;
}
