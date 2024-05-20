-- [[ Highlight on yank ]]
-- See `:help vim.highlight.on_yank()`
local group = vim.api.nvim_create_augroup('UserCommands', { clear = true })

vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = group,
  pattern = '*',
})
