[
  # nmap('<leader>st', ':TodoTelescope<cr>', { desc = 'todo: [s]earch [t]odos' })
  {
    key = "<leader>st";
    action = ":TodoTelescope<cr>";
    mode = "n";
    options = {
      desc = "todo: [s]each [t]odos";
    };
  }
  # nmap('<leader>xt', ':TodoTrouble<cr>', { desc = 'trouble: [t]odos' })
  {
    key = "<leader>xt";
    action = ":TodoTrouble<cr>";
    mode = "n";
    options = {
      desc = "trouble: [t]odos";
    };
  }
]
