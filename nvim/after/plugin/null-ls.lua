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

local null_ls_augroup = vim.api.nvim_create_augroup('UserNullLs', { clear = true })

require('null-ls').setup({
  debug = false,
  sources = {
    require('none-ls.formatting.rustfmt'),
  },
  on_attach = function(client, bufnr)
    if client.server_capabilities.documentFormattingProvider then
      vim.api.nvim_clear_autocmds({ group = null_ls_augroup, buffer = bufnr })
      vim.api.nvim_create_autocmd('BufWritePre', {
        group = null_ls_augroup,
        buffer = bufnr,
        callback = function()
          vim.lsp.buf.format({ bufnr = bufnr })
        end,
      })
    end
  end,
})
