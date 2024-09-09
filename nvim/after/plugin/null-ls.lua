local nmap = require('user.utils').nmap

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
    -- python
    'black',
    -- java
    'google-java-format',
  },
  automatic_installation = false,
  handlers = {},
})

require('null-ls').setup({
  debug = false,
  sources = {
    require('none-ls.formatting.rustfmt'),
  },
  on_attach = function(client)
    if client.server_capabilities.documentFormattingProvider then
      nmap('F', function()
        vim.lsp.buf.format()
      end, { desc = 'lsp: [c]ode [f]ormat' })
    end
  end,
})
