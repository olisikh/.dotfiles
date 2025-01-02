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

    -- NOTE: install plugins that don't have interfacing via nixvim
    require('scala-zio-quickfix').setup({});
  ''
)
  + import ./harpoon.lua.nix
