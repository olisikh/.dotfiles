[
  # nmap('<leader>cd', vim.diagnostic.open_float, { desc = 'diagnostic: show [c]ode [d]iagnostic' })
  {
    key = "grx";
    action = ":lua vim.diagnostic.open_float()<cr>";
    mode = "n";
    options = {
      desc = "lsp: [c]ode [d]iagnostic";
    };
  }
  # nmap('<leader>cf', function() vim.lsp.buf.format() end, { desc = 'lsp: [c]ode [f]ormat' })
  {
    key = "grf";
    action = ":lua require('conform').format()<cr>";
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
    key = "grf";
    action = ":lua require('conform').format()<cr>";
    mode = "v";
    options = {
      desc = "lsp: [c]ode [f]ormat";
    };
  }
  # nmap('<leader>ci', function()
  #   vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
  # end, { desc = 'lsp: toggle inlay hints (buffer)' })
  {
    key = "grh";
    action = ":lua vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())<cr>";
    mode = "n";
    options = {
      desc = "lsp: [c]ode [i]nlay hints";
    };
  }
  # map("n", "<leader>cl", vim.lsp.codelens.run)
  {
    key = "grl";
    action = ":lua vim.lsp.codelens.run()<cr>";
    mode = "n";
    options = {
      desc = "lsp: [g]oto [l]ens";
    };
  }
  # nmap('gd', telescope_builtin.lsp_definitions, { desc = 'lsp: [g]oto [d]efinition' })
  {
    key = "grd";
    action = ":lua require('telescope.builtin').lsp_definitions()<cr>";
    mode = "n";
    options = {
      desc = "lsp: [g]oto [d]efinition";
    };
  }
]
