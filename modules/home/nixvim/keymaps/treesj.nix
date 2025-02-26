[
  # -- For default preset
  # vim.keymap.set('n', '<leader>m', require('treesj').toggle)
  # -- For extending default preset with `recursive = true`
  {
    key = "<leader>m";
    action = ":lua require('treesj').toggle()<cr>";
    mode = "n";
    options = {
      desc = "treesj: toggle";
    };
  }
  # vim.keymap.set('n', '<leader>M', function()
  #     require('treesj').toggle({ split = { recursive = true } })
  # end)
  {
    key = "<leader>M";
    action = ":lua require('treesj').toggle({ split = { recursive = true } })<cr>";
    mode = "n";
    options = {
      desc = "treesj: toggle (recursive)";
    };
  }
]
