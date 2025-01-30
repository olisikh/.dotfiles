[
  # NOTE: DAP
  #
  # nmap('<leader>db', dap.toggle_breakpoint, { desc = 'dap: set breakpoint' })
  {
    key = "<leader>db";
    action = ":lua require('dap').toggle_breakpoint()<cr>";
    mode = "n";
    options = {
      desc = "dap: set breakpoint";
    };
  }
  # nmap('<leader>dB', function()
  #   dap.set_breakpoint(vim.fn.input('Breakpoint condition: '))
  # end, { desc = 'dap: cond breakpoint' })
  {
    key = "<leader>dB";
    action = ":lua require('dap').set_breakpoint(vim.fn.input('Breakpoint condition:'))<cr>";
    mode = "n";
    options = {
      desc = "dap: set breakpoint";
    };
  }
  # nmap('<leader>dc', dap.continue, { desc = 'dap: [c]ontinue' })
  {
    key = "<leader>dc";
    action = ":lua require('dap').continue()<cr>";
    mode = "n";
    options = {
      desc = "dap: [c]ontinue";
    };
  }
  # nmap('<leader>di', dap.step_into, { desc = 'dap: step [i]nto' })
  {
    key = "<leader>dsi";
    action = ":lua require('dap').step_into()<cr>";
    mode = "n";
    options = {
      desc = "dap: [s]tep [i]nto";
    };
  }
  # nmap('<leader>do', dap.step_out, { desc = 'dap: step [o]ut' })
  {
    key = "<leader>dso";
    action = ":lua require('dap').step_out()<cr>";
    mode = "n";
    options = {
      desc = "dap: [s]tep [o]ut";
    };
  }
  # nmap('<leader>dv', dap.step_over, { desc = 'dap: step o[v]er' })
  {
    key = "<leader>dso";
    action = ":lua require('dap').step_over()<cr>";
    mode = "n";
    options = {
      desc = "dap: [s]tep o[v]er";
    };
  }
  # -- nmap('<leader>dr', dap.repl.toggle, { desc = 'dap: repl toggle' })
  {
    key = "<leader>dr";
    action = "lua: require('dap').repl.toggle()<cr>";
    mode = "n";
    options = {
      desc = "dap: [r]epl toggle";
    };
  }
  # -- nmap('<leader>dh', dap_widgets.hover, { desc = 'dap: hover' })
  {
    key = "<leader>dh";
    action = ":lua require('dap.ui.widgets').hover()<cr>";
    mode = "n";
    options = {
      desc = "dap: [h]over";
    };
  }
  #
  # nmap('<leader>dd', dap_ui.toggle, { desc = 'dap-ui: toggle ui' })
  {
    key = "<leader>dd";
    action = ":lua require('dapui').toggle()<cr>";
    mode = "n";
    options = {
      desc = "dap: toggle ui";
    };
  }
  # nmap('<leader>dq', dap.terminate, { desc = 'dap: terminate' })
  {
    key = "<leader>dq";
    action = ":lua require('dap').terminate()<cr>";
    mode = "n";
    options = {
      desc = "dap: terminate";
    };
  }
]

