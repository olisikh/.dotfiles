local null_ls = require('null-ls')
null_ls.setup({})

require('mason-null-ls').setup({
  ensure_installed = {
    'prettier',
    'stylua',
    'gofumpt',
    'goimports',
    'estlint_d',
    'jsonlint',
    'yamllint',
  },
})
