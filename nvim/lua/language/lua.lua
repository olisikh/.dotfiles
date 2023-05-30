local dap = require('dap')

local M = {}

M.setup = function()
  -- setup lua dap
  local lua_group = vim.api.nvim_create_augroup('lua', { clear = true })
  vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'lua' },
    group = lua_group,
    callback = function()
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
