vim.diagnostic.config {
  virtual_text = true
}

local dap = require('dap')
local dapui = require('dapui')
local dap_widgets = require('dap.ui.widgets')

dapui.setup {}

dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end

local map = require('helpers').map

map("n", "<F4>", dap.toggle_breakpoint, { desc = 'dap: toggle breakpoint' })
map("n", "<F5>", dap.continue, { desc = 'dap: continue' })
map("n", "<F6>", dap.step_over, { desc = 'dap: step over' })
map("n", "<F7>", dap.step_into, { desc = 'dap: step into' })
map("n", "<F8>", dap.step_out, { desc = 'dap: step out' })

map("n", "<leader>dr", dap.repl.toggle, { desc = 'dap: repl toggle' })
map("n", "<leader>dK", dap_widgets.hover, { desc = 'dap: hover' })

local sign = vim.fn.sign_define

sign("DapBreakpoint", { text = "●", texthl = "DapBreakpoint", linehl = "", numhl = "" })
sign("DapBreakpointCondition", { text = "●", texthl = "DapBreakpointCondition", linehl = "", numhl = "" })
sign("DapLogPoint", { text = "◆", texthl = "DapLogPoint", linehl = "", numhl = "" })


require("nvim-dap-virtual-text").setup({
  enabled = true,
  enabled_commands = true,
  highlight_changed_variables = true,
  highlight_new_as_changed = true,
  show_stop_reason = true,
  commented = true,
  only_first_definition = true,
  all_references = true,
  display_callback = function(variable, _buf, _stackframe, _node)
    return " " .. variable.name .. " = " .. variable.value .. " "
  end,
  -- experimental features:
  virt_text_pos = "eol",   -- position of virtual text, see `:h nvim_buf_set_extmark()`
  all_frames = false,      -- show virtual text for all stack frames not only current. Only works for debugpy on my machine.
  virt_lines = false,      -- show virtual lines instead of virtual text (will flicker!)
  virt_text_win_col = nil, -- position the virtual text at a fixed window column (starting from the first text column) ,
})


dap.configurations.lua = {
  {
    type = "nlua",
    request = "attach",
    name = "Attach to running Neovim instance",
  },
}

dap.adapters.nlua = function(callback, config)
  callback({ type = "server", host = config.host or "127.0.0.1", port = config.port or 8086 })
end
