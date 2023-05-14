local null_ls = require('null-ls')
null_ls.setup({})

local function setup_handler(formatter)
  null_ls.register(null_ls.builtins.formatting[formatter])
end

require('mason-null-ls').setup({
  ensure_installed = {
    'prettier',
    'stylua',
    'rustfmt',
    -- 'gofumpt'
    -- 'goimports',
  },

  handlers = {
    stylua = setup_handler('stylua'),
    prettier = setup_handler('prettier'),
    rustfmt = setup_handler('rustfmt'),
    -- gofumpt = setup_handler('gofumpt'),
    -- goimports = setup_handler('goimports'),
  },
})
