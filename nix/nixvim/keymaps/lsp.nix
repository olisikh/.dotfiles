[
  # nmap('<leader>cr', vim.lsp.buf.rename, { desc = 'lsp: [r]ename' })
  {
    key = "<leader>cr";
    action = ":lua vim.lsp.buf.rename()<cr>";
    mode = "n";
    options = {
      desc = "lsp: [r]ename";
    };
  }
  # nmap('<leader>ca', vim.lsp.buf.code_action, { desc = 'lsp: [c]ode [a]ction' })
  {
    key = "<leader>ca";
    action = ":lua vim.lsp.buf.code_action()<cr>";
    mode = "n";
    options = {
      desc = "lsp: [c]ode [a]ction";
    };
  }
  # nmap('<leader>cd', vim.diagnostic.open_float, { desc = 'diagnostic: show [c]ode [d]iagnostic' })
  {
    key = "<leader>cd";
    action = ":lua vim.diagnostic.open_float()<cr>";
    mode = "n";
    options = {
      desc = "lsp: [c]ode [d]iagnostic";
    };
  }
  # nmap('<leader>cf', function() vim.lsp.buf.format() end, { desc = 'lsp: [c]ode [f]ormat' })
  {
    key = "<leader>cf";
    action = ":lua vim.lsp.buf.format()<cr>";
    mode = "n";
    options = {
      desc = "lsp: [c]ode [f]ormat";
    };
  }

  # map('v', '<leader>cf', function()
  #   local vstart = vim.fn.getpos("'<")
  #   local vend = vim.fn.getpos("'>")
  #
  #   vim.lsp.buf.format({ range = { vstart, vend } })
  # end, { desc = 'lsp: [c]ode [f]ormat' })
  {
    key = "<leader>cf";
    action = ":lua vim.lsp.buf.format({ range = { vim.fn.getpos(\"'<\"), vim.fn.getpos(\"'>\") } })<cr>";
    mode = "v";
    options = {
      desc = "lsp: [c]ode [f]ormat";
    };
  }
  # nmap('<leader>ci', function()
  #   vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
  # end, { desc = 'lsp: toggle inlay hints (buffer)' })
  {
    key = "<leader>ci";
    action = ":lua vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())<cr>";
    mode = "n";
    options = {
      desc = "lsp: [c]ode [i]nlay hints";
    };
  }
  # nmap('gd', telescope_builtin.lsp_definitions, { desc = 'lsp: [g]oto [d]efinition' })
  {
    key = "gd";
    action = ":lua require('telescope.builtin').lsp_definitions()<cr>";
    mode = "n";
    options = {
      desc = "lsp: [g]oto [d]efinition";
    };
  }
  # nmap('gr', telescope_builtin.lsp_references, { desc = 'lsp: [g]oto [r]eferences' })
  {
    key = "gr";
    action = ":lua require('telescope.builtin').lsp_references()<cr>";
    mode = "n";
    options = {
      desc = "lsp: [g]oto [r]eferences";
    };
  }
]
