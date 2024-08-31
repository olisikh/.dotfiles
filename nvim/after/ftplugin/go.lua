vim.o.tabstop = 4

local dap_go = require('dap-go')

dap_go.setup({
  -- Additional dap configurations can be added.
  -- dap_configurations accepts a list of tables where each entry
  -- represents a dap configuration. For more details do:
  -- :help dap-configuration
  dap_configurations = {
    {
      -- Must be "go" or it will be ignored by the plugin
      type = 'go',
      name = 'Attach remote',
      mode = 'remote',
      request = 'attach',
    },
  },
  -- delve configurations
  delve = {
    -- time to wait for delve to initialize the debug session.
    -- default to 20 seconds
    initialize_timeout_sec = 20,
    -- a string that defines the port to start delve debugger.
    -- default to string "${port}" which instructs nvim-dap
    -- to start the process in a random available port
    port = '${port}',
  },
})

-- nmap('<leader>dt', dap_go.debug_test, { desc = 'dap-go: debug test' })
