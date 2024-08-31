local dap = require('dap')
local mason_registry = require('mason-registry')

local M = {}

M.setup = function(group)
  -- Setup javascript & typescript (mostly dap)
  local js_debugger = mason_registry.get_package('js-debug-adapter'):get_install_path()

  vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' },
    group = group,
    callback = function()
      require('dap-vscode-js').setup({
        node_path = 'node',
        debugger_path = js_debugger,
        debugger_cmd = { 'js-debug-adapter' },
        adapters = { 'pwa-node', 'pwa-chrome', 'pwa-msedge', 'node-terminal', 'pwa-extensionHost' }, -- which adapters to register in nvim-dap
      })

      dap.adapters['pwa-node'] = {
        type = 'server',
        host = 'localhost',
        port = '${port}',
        executable = {
          command = 'js-debug-adapter',
          args = { '${port}' }, -- important because of https://github.com/mxsdev/nvim-dap-vscode-js/issues/42
        },
      }

      -- js and ts debug configs
      for _, language in ipairs({ 'typescript', 'javascript' }) do
        dap.configurations[language] = {
          {
            type = 'pwa-node',
            request = 'launch',
            name = 'Launch file',
            program = '${file}',
            cwd = '${workspaceFolder}',
          },
          {
            type = 'pwa-node',
            request = 'attach',
            name = 'Attach',
            processId = require('dap.utils').pick_process,
            cwd = '${workspaceFolder}',
          },
          {
            type = 'pwa-node',
            request = 'launch',
            name = 'Debug Jest Tests',
            -- trace = true, -- include debugger info
            runtimeExecutable = 'node',
            runtimeArgs = {
              './node_modules/jest/bin/jest.js',
              '--runInBand',
            },
            rootPath = '${workspaceFolder}',
            cwd = '${workspaceFolder}',
            console = 'integratedTerminal',
            internalConsoleOptions = 'neverOpen',
          },
        }
      end

      -- react debug configs
      for _, language in ipairs({ 'typescriptreact', 'javascriptreact' }) do
        dap.configurations[language] = {
          {
            type = 'pwa-chrome',
            name = 'Attach - Remote Debugging',
            request = 'attach',
            program = '${file}',
            cwd = vim.fn.getcwd(),
            sourceMaps = true,
            protocol = 'inspector',
            port = 9222,
            webRoot = '${workspaceFolder}',
          },
          {
            type = 'pwa-chrome',
            name = 'Launch Chrome',
            request = 'launch',
            url = 'http://localhost:3000',
          },
        }
      end
    end,
  })
end

return M
