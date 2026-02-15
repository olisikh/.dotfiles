{ ... }:
{
  imports = [
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
    ./plugins/nvim-java.nix
    ./plugins/which-key.nix
    ./plugins/copilot.nix
    ./plugins/todo-comments.nix
    ./plugins/colorizer.nix
    ./plugins/opencode.nix
    ./plugins/obsidian.nix
    ./plugins/luasnip.nix
    ./plugins/aerial.nix
    ./plugins/indent-blankline.nix
    ./plugins/visual-whitespace.nix
    ./plugins/snacks.nix
    ./plugins/lazygit.nix
    ./plugins/smart-splits.nix
    ./plugins/oil.nix
    ./plugins/smart-splits.nix
    ./plugins/treesj.nix
    ./plugins/trouble.nix
    ./plugins/harpoon.nix
    ./plugins/nvim-metals.nix
    ./plugins/inc-rename.nix
    ./plugins/cellular-automaton.nix
    ./plugins/zen-mode.nix
    ./plugins/guess-indent.nix
    ./plugins/neogen.nix
    ./plugins/99.nix
  ];

  plugins = {
    lz-n.enable = true;
    web-devicons.enable = true;
    mini-icons.enable = true;
    nvim-autopairs.enable = true;
    sleuth.enable = true;
    render-markdown.enable = true;
    hardtime.enable = true;
    friendly-snippets.enable = true;
    helm.enable = true;
    crates.enable = true;
    fidget.enable = true;
    nvim-surround.enable = true;
    lazydev.enable = true;
  };
}
