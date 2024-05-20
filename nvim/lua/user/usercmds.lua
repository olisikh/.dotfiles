local cmp = require('cmp')

vim.api.nvim_create_user_command('CopilotToggle', function()
  local status = require('copilot_status').status()

  if status.status == 'offline' then
    vim.cmd([[Copilot enable]])
  else
    vim.cmd([[Copilot disable]])
  end
end, { nargs = 0 })

local cached_codeium = nil
vim.api.nvim_create_user_command('CodeiumToggle', function(_)
  local codeium = cmp.core:get_sources(function(source)
    return source.name == 'codeium'
  end)[1]

  if codeium ~= nil then
    cmp.core:unregister_source(codeium.id)
    cached_codeium = codeium
  elseif cached_codeium ~= nil then
    cmp.core:register_source(cached_codeium)
  end
end, { nargs = 0 })
