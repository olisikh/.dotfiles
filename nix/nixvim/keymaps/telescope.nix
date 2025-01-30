[
  # nmap('<leader>?', telescope_builtin.oldfiles, { desc = 'telescope: find recently opened files' })
  {
    key = "<leader>?";
    action = ":lua require('telescope.builtin').oldfiles()<cr>";
    mode = "n";
    options = {
      desc = "telescope: recent files";
    };
  }
  # nmap('<leader><space>', telescope_builtin.buffers, { desc = 'telescope: find existing buffers' })
  {
    key = "<leader>.";
    action = ":lua require('telescope.builtin').buffers()<cr>";
    mode = "n";
    options = {
      desc = "telescope: buffers";
    };
  }
  # nmap('<leader>/', function()
  #   telescope_builtin.current_buffer_fuzzy_find(telescope_themes.get_dropdown({ winblend = 10, previewer = false }))
  # end, { desc = 'telescope: fuzzy find in current buffer' })
  {
    key = "<leader>sb";
    action = ":lua require('telescope.builtin').current_buffer_fuzzy_find(require('telescope.themes').get_dropdown({ winblend = 10, previewer = false }))<cr>";
    mode = "n";
    options = {
      desc = "telescope: [s]earch [b]uffer";
    };
  }
  #
  # nmap('<leader>sf', telescope_builtin.git_files, { desc = 'telescope: [s]earch [f]iles' })
  {
    key = "<leader>sf";
    action = ":lua require('telescope.builtin').git_files()<cr>";
    mode = "n";
    options = {
      desc = "telescope: [s]earch [f]iles";
    };
  }
  # nmap('<leader>sp', telescope_builtin.find_files, { desc = 'telescope: [s]earch [p]roject files' })
  {
    key = "<leader>sp";
    action = ":lua require('telescope.builtin').find_files()<cr>";
    mode = "n";
    options = {
      desc = "telescope: search [p]roject [f]iles";
    };
  }
  # nmap('<leader>sh', telescope_builtin.help_tags, { desc = 'telescope: [s]earch [h]elp' })
  {
    key = "<leader>sh";
    action = ":lua require('telescope.builtin').help_tags()<cr>";
    mode = "n";
    options = {
      desc = "telescope: search [h]elp";
    };
  }
  # nmap('<leader>sw', telescope_builtin.grep_string, { desc = 'telescope: [s]earch current [w]ord' })
  {
    key = "<leader>sw";
    action = ":lua require('telescope.builtin').grep_string()<cr>";
    mode = "n";
    options = {
      desc = "telescope: [s]earch [w]ord";
    };
  }
  # nmap('<leader>sg', telescope_builtin.live_grep, { desc = 'telescope: [s]earch by [g]rep' })
  {
    key = "<leader>sg";
    action = ":lua require('telescope.builtin').live_grep()<cr>";
    mode = "n";
    options = {
      desc = "telescope: [s]earch [g]rep";
    };
  }
  # nmap('<leader>sd', telescope_builtin.diagnostics, { desc = 'telescope: [s]earch [d]iagnostics' })
  {
    key = "<leader>sd";
    action = ":lua require('telescope.builtin').diagnostics()<cr>";
    mode = "n";
    options = {
      desc = "telescope: [s]earch [d]iagnostics";
    };
  }
  # nmap('<leader>sk', telescope_builtin.keymaps, { desc = 'telescope: [s]earch [k]eymaps' })
  {
    key = "<leader>sk";
    action = ":lua require('telescope.builtin').keymaps()<cr>";
    mode = "n";
    options = {
      desc = "telescope: [s]earch [k]eymaps";
    };
  }
]
