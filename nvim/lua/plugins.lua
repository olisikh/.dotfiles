require('lazy').setup({
  -- Catppuccin theme
  { 'catppuccin/nvim', name = 'catppuccin', priority = 1000 },

  -- icons
  { 'nvim-tree/nvim-web-devicons', opts = {} },

  -- Statusline plugin
  'nvim-lualine/lualine.nvim',

  -- tmux integration plugin
  { 'christoomey/vim-tmux-navigator', lazy = false },

  -- required by most plugins
  'nvim-lua/plenary.nvim',

  -- Git plugin
  { 'tpope/vim-fugitive', dependencies = { 'tpope/vim-rhubarb' } },

  -- File tree explorer
  'nvim-tree/nvim-tree.lua',

  -- Traverse diagnostics in a separate window
  'folke/trouble.nvim',

  -- quick navigation between frequently used files
  'theprimeagen/harpoon',

  -- undo tree history
  'mbbill/undotree',

  -- Autocompletion (cmp), integration with lsp, ai, snippets, etc.
  {
    'hrsh7th/nvim-cmp',
    dependencies = {
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/vim-vsnip',
      'hrsh7th/vim-vsnip-integ',
      'hrsh7th/cmp-nvim-lsp-signature-help',
      'L3MON4D3/LuaSnip',
      'saadparwaiz1/cmp_luasnip',
      -- Beautiful nerd font icons in cmp
      'onsails/lspkind-nvim',
    },
  },

  {
    -- LSP Configuration & Plugins
    'neovim/nvim-lspconfig',
    dependencies = {
      -- Automatically install LSPs to stdpath for neovim
      { 'williamboman/mason.nvim', opts = { ui = { border = 'rounded' } } },
      { 'williamboman/mason-lspconfig.nvim' },
      {
        'jay-babu/mason-null-ls.nvim',
        event = { 'BufReadPre', 'BufNewFile' },
        dependencies = { 'nvimtools/none-ls.nvim' },
      },
      {
        'jay-babu/mason-nvim-dap.nvim',
        dependencies = { 'mfussenegger/nvim-dap' },
      },
    },
  },

  -- status updates for LSP showing on the right
  { 'j-hui/fidget.nvim', opts = {} },

  -- Additional lua configuration, makes nvim stuff amazing!
  {
    'folke/neodev.nvim',
    opts = {
      library = {
        plugins = { 'nvim-dap-ui', 'neotest' },
        types = true,
      },
    },
  },

  -- Scala metals
  'scalameta/nvim-metals',

  -- Rust tools & others
  { 'simrat39/rust-tools.nvim', ft = 'rust' },
  { 'saecki/crates.nvim', opts = {}, ft = { 'rust', 'toml' } },

  -- Debugging
  {
    'mfussenegger/nvim-dap',
    dependencies = {
      { 'theHamsta/nvim-dap-virtual-text' },
      { 'rcarriga/nvim-dap-ui' },
      { 'jbyuki/one-small-step-for-vimkind' }, -- debug lua
      { 'leoluz/nvim-dap-go' }, -- debug go
      { 'mxsdev/nvim-dap-vscode-js' }, -- debug js
    },
  },

  -- Fuzzy Finder (files, lsp, etc)
  {
    'nvim-telescope/telescope.nvim',
    dependencies = {
      {
        -- Fuzzy Finder Algorithm which requires local dependencies to be built.
        -- Only load if `make` is available. Make sure you have the system
        -- requirements installed.
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        cond = function()
          return vim.fn.executable('make') == 1
        end,
      },
      'nvim-telescope/telescope-frecency.nvim',
      'nvim-telescope/telescope-dap.nvim',
      'nvim-telescope/telescope-ui-select.nvim',
    },
  },

  -- Treesitter: highlight, edit, and navigate code
  {
    'nvim-treesitter/nvim-treesitter',
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
      'nvim-treesitter/nvim-treesitter-context',
      -- LSP enhance plugin
      { 'glepnir/lspsaga.nvim', event = 'LspAttach' },
    },
    config = function()
      pcall(require('nvim-treesitter.install').update({ with_sync = true }))
    end,
  },

  -- Unofficial Codeium plugin, interactive AI autocomplete
  {
    'Exafunction/codeium.nvim',
    event = 'InsertEnter',
    opts = {},
  },

  -- Detect tabstop and shiftwidth automatically
  'tpope/vim-sleuth',

  -- Multi-cursor selection ctrl+up/down - to add cursor, ctrl+n - select next word, shift-arrow - per char
  'mg979/vim-visual-multi',

  -- Auto add closing bracket or closing quote
  { 'windwp/nvim-autopairs', opts = {} },

  -- Surround text objects, ys - surround, ds - delete around, cs - change around
  {
    'kylechui/nvim-surround',
    version = '*',
    event = 'VeryLazy',
    opts = {},
  },

  -- Smart join lines in blocks
  'Wansmer/treesj',

  -- Useful plugin to show you pending keybinds.
  'folke/which-key.nvim',

  -- Adds git releated signs to the gutter, as well as utilities for managing changes
  'lewis6991/gitsigns.nvim',

  -- Add indentation function/class/etc context lines
  { 'lukas-reineke/indent-blankline.nvim', main = 'ibl', opts = {} },

  -- Comment lines and blocks with 'gcc', 'gbc'
  { 'numToStr/Comment.nvim', opts = {} },

  --  comments highlighting and navigation
  { 'folke/todo-comments.nvim' },

  -- nice notifications in vim
  {
    'rcarriga/nvim-notify',
    config = function()
      -- globally setup nvim-notify to be nvim notifications provider
      vim.notify = require('notify')
    end,
  },

  -- 'vim-test/vim-test',
  {
    -- Neotest framework for running tests
    'nvim-neotest/neotest',
    dependencies = {
      'nvim-neotest/neotest-plenary',
      'nvim-neotest/neotest-go',
      'stevanmilic/neotest-scala',
      'rouge8/neotest-rust',
    },
  },
}, {
  lockfile = vim.fn.stdpath('data') .. '/lazy/lazy-lock.json',
  ui = {
    border = 'rounded',
  },
})
