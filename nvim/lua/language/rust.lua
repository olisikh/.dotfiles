local M = {}

M.setup = function(capabilities, attach_lsp)
  local nmap = require('helpers').nmap

  -- Setup rust and debugging
  local mason_registry = require('mason-registry')
  local codelldb_root = mason_registry.get_package('codelldb'):get_install_path() .. '/extension/'
  local codelldb_path = codelldb_root .. 'adapter/codelldb'
  local liblldb_path = codelldb_root .. 'lldb/lib/liblldb.dylib'

  vim.g.rustaceanvim = function()
    local cfg = require('rustaceanvim.config')

    return {
      -- LSP configuration
      server = {
        on_attach = function(client, bufnr)
          attach_lsp(client, bufnr)

          -- you can also put keymaps in here
          nmap('<leader>ra', function()
            vim.cmd.RustLsp({ 'hover', 'actions' })
          end, { desc = 'rust: hover actions' })

          nmap('<leader>rr', function()
            vim.cmd.RustLsp('runnables')
          end, { desc = 'rust: run runnable' })

          nmap('<leader>rd', function()
            vim.cmd.RustLsp('debuggables')
          end, { desc = 'rust: run debug' })

          nmap('<leader>rt', function()
            vim.cmd.RustLsp('testables')
          end, { desc = 'rust: run test' })

          nmap('<leader>re', function()
            vim.cmd.RustLsp('expandError')
          end, { desc = 'rust: explain error' })
        end,
      },
      -- DAP configuration
      dap = {
        adapter = cfg.get_codelldb_adapter(codelldb_path, liblldb_path),
      },
    }
  end
end

return M
