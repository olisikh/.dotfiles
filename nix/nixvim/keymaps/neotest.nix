[
  # NOTE: NeoTest
  # nmap('<leader>tr', neotest.run.run, { desc = 'neotest: run nearest test' })
  {
    key = "<leader>tr";
    action = ":lua require('neotest').run.run()<cr>";
    mode = "n";
    options = {
      desc = "neotest: run nearest test";
    };
  }
  # nmap('<leader>td', function() neotest.run.run({ strategy = 'dap' }) end, { desc = 'neotest: debug nearest test' })
  {
    key = "<leader>td";
    action = ":lua require('neotest').run.run({strategy = 'dap' })<cr>";
    mode = "n";
    options = {
      desc = "neotest: debug nearest test";
    };
  }
  # nmap('<leader>tR', function() neotest.run.run(vim.fn.expand('%')) end, { desc = 'neotest: run current file' })
  {
    key = "<leader>tR";
    action = ":lua require('neotest').run.run(vim.fn.expand('%'))<cr>";
    mode = "n";
    options = {
      desc = "neotest: run tests in buffer";
    };
  }
  # nmap('<leader>tD', function() neotest.run.run({ vim.fn.expand('%'), strategy = 'dap' }) end, { desc = 'neotest: debug current file' })
  {
    key = "<leader>tD";
    action = ":lua require('neotest').run.run({ vim.fn.expand('%'), strategy = 'dap' })<cr>";
    mode = "n";
    options = {
      desc = "neotest: debug tests in buffer";
    };
  }
  # nmap('<leader>ta', neotest.run.attach, { desc = 'neotest: attach to nearest test' })
  {
    key = "<leader>ta";
    action = ":lua require('neotest').run.attach()<cr>";
    mode = "n";
    options = {
      desc = "neotest: attach to nearest test";
    };
  }
  # nmap('<leader>tS', neotest.summary.toggle, { desc = 'neotest: toggle test summary' })
  {
    key = "<leader>ti";
    action = ":lua require('neotest').summary.toggle()<cr>";
    mode = "n";
    options = {
      desc = "neotest: toggle test info";
    };
  }
  # nmap('<leader>ts', neotest.run.stop, { desc = 'neotest: stop nearest test' })
  {
    key = "<leader>ts";
    action = ":lua require('neotest').run.stop()<cr>";
    mode = "n";
    options = {
      desc = "neotest: stop nearest test";
    };
  }
  # nmap('<leader>to', neotest.output_panel.toggle, { desc = 'neotest: open output panel' })
  {
    key = "<leader>to";
    action = ":lua require('neotest').output_panel.toggle()<cr>";
    mode = "n";
    options = {
      desc = "neotest: toggle test output";
    };
  }
  # nmap('<leader>tO', function() neotest.output.open({ enter = true }) end, { desc = 'neotest: open output floating window' })
  {
    key = "<leader>tO";
    action = ":lua require('neotest').output.panel({ enter = true })<cr>";
    mode = "n";
    options = {
      desc = "neotest: toggle test output (floating window)";
    };
  }
  # nmap('[t', function() neotest.jump.prev({ status = 'failed' }) end, { desc = 'neotest: jump to prev failed test' })
  {
    key = "[t";
    action = ":lua require('neotest').jump.prev({ status = 'failed' })<cr>";
    mode = "n";
    options = {
      desc = "neotest: jump to prev failed test";
    };
  }
  # nmap(']t', function() neotest.jump.next({ status = 'failed' }) end, { desc = 'neotest: jump to prev failed test' })
  {
    key = "]t";
    action = ":lua require('neotest').jump.next({ stauts = 'failed' })<cr>";
    mode = "n";
    options = {
      desc = "neotest: jump to next failed test";
    };
  }
]
