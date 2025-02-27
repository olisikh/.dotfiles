{ kotlin-dap-adapter }:
(
# lua
''
  vim.loop.fs_mkdir(vim.o.backupdir, 750)
  vim.loop.fs_mkdir(vim.o.directory, 750)
  vim.loop.fs_mkdir(vim.o.undodir, 750)

  -- set backup directory to be a subdirectory of data to ensure that backups are not written to git repos
  vim.o.backupdir = vim.fn.stdpath("data") .. "/backup"

  -- Configure 'directory' to ensure that Neovim swap files are not written to repos.
  vim.o.directory = vim.fn.stdpath("data") .. "/directory" 
  vim.o.sessionoptions = vim.o.sessionoptions .. ",globals"

  -- set undodir to ensure that the undofiles are not saved to git repos.
  vim.o.undodir = vim.fn.stdpath("data") .. "/undo" 

  -- NOTE: replace generic letter signs with nice icons for diagnostics
  local signs = { Error = ' ', Warn = ' ', Hint = ' ', Info = ' ' }
  for type, icon in pairs(signs) do
    local hl = 'DiagnosticSign' .. type
    vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
  end

  -- NOTE: setup border for ui elements
  local border = "rounded"

  vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
    vim.lsp.handlers.hover, { border = border }
  )

  vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(
    vim.lsp.handlers.signature_help, { border = border }
  )

  vim.diagnostic.config { float = { border = border } }

  require('lspconfig.ui.windows').default_options = { border = border }

  -- NOTE: open and close DAP UI when debugging on/off
  require('dap').listeners.after.event_initialized['dapui_config'] = require('dapui').open
  require('dap').listeners.before.event_terminated['dapui_config'] = require('dapui').close
  require('dap').listeners.before.event_exited['dapui_config'] = require('dapui').close

  -- TODO: requires a plugin to be installed
  require('scala-zio-quickfix').setup({});

  -- TODO: configure nvim-dap-kotlin
  -- polyfil a function that is used by plugin
  require('dap-kotlin').setup({
    dap_command = "${kotlin-dap-adapter}/bin/kotlin-debug-adapter"
  })
'') + import ./harpoon.lua.nix
