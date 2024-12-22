local M = {}

function M.setup(group, capabilities)
  vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'kotlin' },
    group = group,
    callback = function()
      vim.print('Setting up Kotlin DAP')
      require('dap-kotlin').setup({
        dap_command = 'kotlin-debug-adapter',
        project_root = '${workspaceFolder}',
        enable_logging = false,
        log_file_path = '',
      })
      vim.print('Finished Kotlin DAP setup')
    end,
  })
end

return M
