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
  on_attach = function(client, bufnr)
    -- NOTE: if null-ls has a formatter for given filetype, install keymap for formatting the buffer
    if client.server_capabilities.documentFormattingProvider then
      nmap('F', function()
        vim.lsp.buf.format({ bufnr = bufnr })
      end, { desc = 'lsp: [c]ode [f]ormat' })
    end
  end,
})
