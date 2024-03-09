local nmap = require('helpers').nmap

local dap = require('dap')
local breakpoints = require('dap.breakpoints')
local dap_utils = require('dap.utils')
local dap_ui = require('dapui')
local dap_widgets = require('dap.ui.widgets')
local mason_dap = require('mason-nvim-dap')

mason_dap.setup({
  ensure_installed = {
    'codelldb',
    'js',
    'delve',
  },
})

dap_ui.setup({})

dap.listeners.after.event_initialized['dapui_config'] = function()
  -- local buf = vim.api.nvim_get_current_buf()
  -- local bps = breakpoints.get(buf)
  --
  -- vim.print(bps)
  -- vim.print(dap_utils.non_empty(bps))

  dap_ui.open()
end
dap.listeners.before.event_terminated['dapui_config'] = function()
  dap_ui.close()
end
dap.listeners.before.event_exited['dapui_config'] = function()
  dap_ui.close()
end

nmap('<F1>', dap_ui.toggle, { desc = 'dap-ui: toggle' })
nmap('<F2>', dap.set_breakpoint, { desc = 'dap: set breakpoint' })
nmap('<F3>', function()
  dap.set_breakpoint(vim.fn.input('Breakpoint condition: '))
end, { desc = 'dap: cond breakpoint' })
nmap('<F4>', dap.toggle_breakpoint, { desc = 'dap: breakpoint' })
nmap('<F5>', dap.continue, { desc = 'dap: continue' })
nmap('<F6>', dap.step_over, { desc = 'dap: step over' })
nmap('<F7>', dap.step_into, { desc = 'dap: step into' })
nmap('<F8>', dap.step_out, { desc = 'dap: step out' })

nmap('<leader>dr', dap.repl.toggle, { desc = 'dap: repl toggle' })
nmap('<leader>dh', dap_widgets.hover, { desc = 'dap: hover' })
nmap('<leader>do', dap_ui.toggle, { desc = 'dap-ui: toggle ui' })
nmap('<leader>dq', dap.terminate, { desc = 'dap: terminate' })
nmap('<leader>dr', function()
  dap.restart({ terminateDebugee = false })
end, { desc = 'dap: restart dap' })
nmap('<leader>dR', function()
  dap.restart({ terminateDebugee = true })
end, { desc = 'dap: terminate & restart dap' })

local sign = vim.fn.sign_define

sign('DapBreakpoint', { text = '●', texthl = 'DapBreakpoint', linehl = '', numhl = '' })
sign('DapBreakpointCondition', { text = '●', texthl = 'DapBreakpointCondition', linehl = '', numhl = '' })
sign('DapBreakpointRejected', { text = '●', texthl = 'DapBreakpointRejected', linehl = '', numhl = '' })
sign('DapStopped', { text = '→', texthl = 'DapStopped', linehl = '', numhl = '' })
sign('DapLogPoint', { text = '◆', texthl = 'DapLogPoint', linehl = '', numhl = '' })

require('nvim-dap-virtual-text').setup({
  enabled = true,
  enabled_commands = true,
  highlight_changed_variables = true,
  highlight_new_as_changed = true,
  show_stop_reason = true,
  commented = true,
  only_first_definition = true,
  all_references = true,
  display_callback = function(variable, _buf, _stackframe, _node)
    return ' ' .. variable.name .. ' = ' .. variable.value .. ' '
  end,
  -- experimental features:
  virt_text_pos = 'eol',   -- position of virtual text, see `:h nvim_buf_set_extmark()`
  all_frames = false,      -- show virtual text for all stack frames not only current. Only works for debugpy on my machine.
  virt_lines = false,      -- show virtual lines instead of virtual text (will flicker!)
  virt_text_win_col = nil, -- position the virtual text at a fixed window column (starting from the first text column) ,
})
