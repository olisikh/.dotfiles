[
  # nmap('-', oil.open, { desc = 'oil: open parent directory' })
  {
    key = "-";
    action = ":lua require('oil').open()<cr>";
    mode = "n";
    options = {
      desc = "oil: open parent folder";
    };
  }
  # nmap('_', function() oil.open(vim.uv.cwd()) end, { desc = 'oil: open cwd directory' })
  {
    key = "_";
    action = ":lua require('oil').open(vim.uv.cwd()))<cr>";
    mode = "n";
    options = {
      desc = "oil: open cwd folder";
    };
  }
]
