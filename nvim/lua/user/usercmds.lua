vim.api.nvim_create_user_command('CopilotToggle', function()
  local status = require('copilot_status').status()

  if status.status == 'offline' then
    vim.cmd([[Copilot enable]])
  else
    vim.cmd([[Copilot disable]])
  end
end, { nargs = 0 })
