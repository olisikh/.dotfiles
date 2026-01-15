{ lib, ... }:
{
  plugins = {
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
        on_attach = lib.nixvim.mkRaw ''
          function(bufnr)
            require("nvim-tree.api")
              .config
              .mappings
              .default_on_attach(bufnr)
          end
        '';
      };
    };
  };

  keymaps = [
    # nmap('<leader>o', api.tree.toggle, { desc = 'nvim-tree: toggle', noremap = true })
    {
      key = "<leader>ft";
      action = ":lua require('nvim-tree.api').tree.toggle()<cr>";
      mode = "n";
      options = {
        desc = "nvim-tree: toggle";
        noremap = true;
      };
    }
    # nmap('<leader>O', ':NvimTreeFindFile<cr>', { desc = 'nvim-tree: locale file in a tree', noremap = true })
    {
      key = "<leader>fn";
      action = ":NvimTreeFindFile<cr>";
      mode = "n";
      options = {
        desc = "nvim-tree: navigate to file";
        noremap = true;
      };
    }
  ];
}
