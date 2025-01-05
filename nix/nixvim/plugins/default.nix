{ pkgs, ... }:
{
  plugins = {
    lz-n.enable = true;
    web-devicons.enable = true;
    lualine.enable = true;
    oil.enable = true;
    nvim-tree.enable = true;
    smart-splits.enable = true;
    treesitter.enable = true;
    treesitter-refactor.enable = true;
    treesitter-textobjects.enable = true;
    treesitter-context.enable = true;
    nvim-autopairs.enable = true;
    lazygit.enable = true;
    dap.enable = true;
    neotest.enable = true;
    trouble.enable = true;
    sleuth.enable = true;
    colorizer.enable = true;
    gitsigns.enable = true;
    which-key.enable = true;
    markdown-preview.enable = true;
    render-markdown.enable = true;
    telescope.enable = true;
    todo-comments.enable = true;
    copilot-lua.enable = true;
    undotree.enable = true;
    hardtime.enable = true;
    blink-cmp.enable = true;
    lsp.enable = true;
    lint.enable = true;
    conform-nvim.enable = true;
    none-ls.enable = true;
    helm.enable = true;
    rustaceanvim.enable = true;
    crates.enable = true;
    fidget.enable = true;
    nvim-surround.enable = true;
    nix.enable = true;
  }
  // import ./blink-cmp.nix
  // import ./dap.nix { inherit pkgs; }
  // import ./gitsigns.nix
  // import ./lsp.nix
  // import ./lint.nix
  // import ./conform-nvim.nix
  // import ./lualine.nix
  // import ./markdown-preview.nix
  // import ./neotest.nix { inherit pkgs; }
  // import ./none-ls.nix
  // import ./nvim-tree.nix
  // import ./telescope.nix
  // import ./treesitter.nix { inherit pkgs; }
  // import ./undotree.nix
  // import ./rustaceanvim.nix { inherit pkgs; }
  // import ./which-key.nix
  // import ./copilot-lua.nix;
}
