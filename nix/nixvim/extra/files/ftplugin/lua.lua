local lazydev = require('lazydev')
local bufnr = vim.api.nvim_get_current_buf()

lazydev.setup({
  enabled = true
})

lazydev.find_workspace(bufnr)
