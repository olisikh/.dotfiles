local null_ls = require('null-ls')
null_ls.setup({})

require('mason-null-ls').setup({
  ensure_installed = {
    'prettier',
    'stylua',
    'rustfmt',
    'gofumpt',
    'goimports',
  },
})
