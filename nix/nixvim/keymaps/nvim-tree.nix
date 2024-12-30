[
  # nmap('<leader>o', api.tree.toggle, { desc = 'nvim-tree: toggle', noremap = true })
  {
    key = "<leader>o";
    action = ":lua require('nvim-tree.api').tree.toggle()<cr>";
    mode = "n";
    options = {
      desc = "nvim-tree: toggle";
      noremap = true;
    };
  }
  # nmap('<leader>O', ':NvimTreeFindFile<cr>', { desc = 'nvim-tree: locale file in a tree', noremap = true })
  {
    key = "<leader>O";
    action = ":NvimTreeFindFile<cr>";
    mode = "n";
    options = {
      desc = "nvim-tree: navigate to file";
      noremap = true;
    };
  }
]
