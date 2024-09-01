
local M = {}

function M.setup(group)

-- setup lua dap
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'lua' },
  group = group,
  callback = function()
    local dap = require('dap')

    dap.configurations.lua = {
      {
        type = 'nlua',
        request = 'attach',
        name = 'Attach to running Neovim instance',
      },
    }

    dap.adapters.nlua = function(callback, config)
      callback({
        type = 'server',
        host = config.host or '127.0.0.1',
        port = config.port or 8086,
      })
    end
  end,
})
end

return M
