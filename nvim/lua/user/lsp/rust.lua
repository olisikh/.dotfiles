local nmap = require('user.utils').nmap

local M = {}

M.setup = function(group, capabilities)
  -- Setup rust and debugging
  local mason_registry = require('mason-registry')
  local codelldb_root = mason_registry.get_package('codelldb'):get_install_path() .. '/extension/'
  local codelldb_path = codelldb_root .. 'adapter/codelldb'
  local liblldb_path = codelldb_root .. 'lldb/lib/liblldb.dylib'

  vim.g.rustaceanvim = function()
    local config = require('rustaceanvim.config')

    return {
      -- LSP configuration
      server = {
        capabilitis = capabilities,
        on_attach = function(client, bufnr)
          nmap('<leader>ce', function()
            vim.cmd.RustLsp('explainError')
          end, { desc = 'rust: explain [c]ode [e]rror' })
        end,
      },
      -- DAP configuration
      dap = {
        adapter = config.get_codelldb_adapter(codelldb_path, liblldb_path),
      },
    }
  end
end

return M
