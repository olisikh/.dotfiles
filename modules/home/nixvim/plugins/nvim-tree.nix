{ nixvimLib, ... }:
{
  # NOTE: :h nvim-tree for more settings,
  # or find them here: https://github.com/nvim-tree/nvim-tree.lua/blob/48a92907575df1dbd7242975a04e98169cb3a115/doc/nvim-tree-lua.txt
  nvim-tree = {
    enable = true;
    settings = {
      renderer = {
        icons = {
          git_placement = "after";
        };
      };
      view = {
        width = 50;
      };
      git = {
        enable = true;
        ignore = true;
      };
      filters = {
        dotfiles = true;
      };
      on_attach = nixvimLib.mkRaw # lua
        ''
          function(bufnr)
            require("nvim-tree.api")
              .config
              .mappings
              .default_on_attach(bufnr)
          end
        '';
    };
  };
}
