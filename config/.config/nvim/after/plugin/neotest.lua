local nmap = require('helpers').nmap
local neotest = require('neotest')

local neotest_namespace = vim.api.nvim_create_namespace("neotest")
vim.diagnostic.config({
  virtual_text = {
    format = function(diagnostic)
      return diagnostic.message:gsum("\n", " "):gsub("\t", " "):gsub("%s+", " "):gsub("^%s+", "")
    end
  }
}, neotest_namespace)

neotest.setup({
  adapters = {
    require("neotest-go"),
    require("neotest-scala"),
    require("neotest-rust") {
      dap_adapter = "rt_lldb",
    }
  }
})

nmap("<leader>rt", neotest.run.run, { desc = "neotest: run nearest test" })
nmap("<leader>rT", function() neotest.run.run(vim.fn.expand("%")) end, { desc = "neotest: run current file" })
nmap("<leader>dt", function() neotest.run.run({ strategy = "dap" }) end, { desc = "neotest: debug nearest test" })
nmap("<leader>rs", neotest.run.stop, { desc = "neotest: stop nearest test" })
nmap("<leader>ra", neotest.run.attach, { desc = "neotest: attach to nearest test" })
