require('mason-null-ls').setup({
  ensure_installed = {
    -- js
    'prettierd',
    'eslint_d',
    -- lua
    'stylua',
    -- go
    'gofumpt',
    'goimports',
    -- json/yaml
    'jsonlint',
    'yamllint',
    -- nix
    'nixpkgs-fmt',
  },
  automatic_installation = false,
  handlers = {},
})

require('null-ls').setup({
  sources = {
    -- Anything not supported by mason.
  },
})
