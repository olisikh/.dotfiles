-- [[ Highlight on yank ]]
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup('UserHighlight', { clear = true })

vim.api.nvim_create_autocmd('TextYankPost', {
  callback = vim.highlight.on_yank,
  group = highlight_group,
  pattern = '*',
})
