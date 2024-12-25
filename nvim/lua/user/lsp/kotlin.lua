local M = {}

function M.setup(group, capabilities)
  vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'kotlin' },
    group = group,
    callback = function()
      require('dap-kotlin').setup({})
    end,
  })
end

return M
