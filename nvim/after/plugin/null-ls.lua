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
  },
  automatic_installation = false,
  handlers = {},
})

local null_ls_augroup = vim.api.nvim_create_augroup('UserNullLs', { clear = true })

require('null-ls').setup({
  debug = false,
  sources = {
    require('none-ls.formatting.rustfmt'),
  },
  on_attach = function(client, bufnr)
    if client.server_capabilities.documentFormattingProvider then
      require('user.lsp_utils').setup_lsp_buffer(null_ls_augroup, client, bufnr)
    end
  end,
})
