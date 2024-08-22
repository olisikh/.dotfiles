require('lazy').setup({
  -- catppuccin theme
  { 'catppuccin/nvim', name = 'catppuccin', lazy = false, priority = 1000 },

  -- statusline plugin
  'nvim-lualine/lualine.nvim',

  -- for wezterm
  { 'willothy/wezterm.nvim', config = true },

  {
    'mrjones2014/smart-splits.nvim',
    lazy = false,
    config = function()
      local s = require('smart-splits')

      vim.keymap.set('n', '<A-h>', s.resize_left)
      vim.keymap.set('n', '<A-j>', s.resize_down)
      vim.keymap.set('n', '<A-k>', s.resize_up)
      vim.keymap.set('n', '<A-l>', s.resize_right)
      -- moving between splits
      vim.keymap.set('n', '<C-h>', s.move_cursor_left)
      vim.keymap.set('n', '<C-j>', s.move_cursor_down)
      vim.keymap.set('n', '<C-k>', s.move_cursor_up)
      vim.keymap.set('n', '<C-l>', s.move_cursor_right)
      vim.keymap.set('n', '<C-\\>', s.move_cursor_previous)
      -- swapping buffers between windows
      vim.keymap.set('n', '<leader><leader>h', s.swap_buf_left)
      vim.keymap.set('n', '<leader><leader>j', s.swap_buf_down)
      vim.keymap.set('n', '<leader><leader>k', s.swap_buf_up)
      vim.keymap.set('n', '<leader><leader>l', s.swap_buf_right)
    end,
  },

  -- required by most plugins
  'nvim-lua/plenary.nvim',

  -- git plugin
  {
    'kdheepak/lazygit.nvim',
    cmd = {
      'LazyGit',
      'LazyGitConfig',
      'LazyGitCurrentFile',
      'LazyGitFilter',
      'LazyGitFilterCurrentFile',
    },
    -- setting the keybinding for LazyGit with 'keys' is recommended in
    -- order to load the plugin when the command is run for the first time
    keys = {
      { '<leader>lg', '<cmd>LazyGit<cr>', desc = 'lazygit: Open [l]azygit' },
      { '<leader>lc', '<cmd>LazyGitCurrentFile<cr>', desc = 'lazygit: [c]urrent file' },
      { '<leader>lf', '<cmd>LazyGitFilter<cr>', desc = 'lazygit: [f]ilter' },
      { '<leader>lF', '<cmd>LazyGitFilterCurrentFile<cr>', desc = 'lazygit: [F]ilter current file' },
    },
  },

  -- file tree explorer
  { 'nvim-tree/nvim-tree.lua', dependencies = { 'nvim-tree/nvim-web-devicons' } },

  -- file system management within neovim buffer
  { 'stevearc/oil.nvim', dependencies = { 'nvim-tree/nvim-web-devicons' } },

  -- traverse diagnostics in a separate window
  'folke/trouble.nvim',

  -- quick navigation between frequently used files
  {
    'letieu/harpoon-lualine',
    dependencies = {
      {
        'ThePrimeagen/harpoon',
        branch = 'harpoon2',
      },
    },
  },

  -- undo tree history
  'mbbill/undotree',
  -- forever undo
  {
    'kevinhwang91/nvim-fundo',
    dependencies = { 'kevinhwang91/promise-async' },
    config = function()
      require('fundo').install()
    end,
  },

  -- autocompletion (cmp), integration with lsp, ai, snippets, etc.
  {
    'hrsh7th/nvim-cmp',
    dependencies = {
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/vim-vsnip',
      'hrsh7th/vim-vsnip-integ',
      'hrsh7th/cmp-nvim-lsp-signature-help',
      'L3MON4D3/LuaSnip',
      'saadparwaiz1/cmp_luasnip',
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
        dependencies = {
          'nvimtools/none-ls.nvim',
          'nvimtools/none-ls-extras.nvim',
        },
      },
      {
        'jay-babu/mason-nvim-dap.nvim',
        dependencies = { 'mfussenegger/nvim-dap' },
      },
    },
  },

  { 'towolf/vim-helm', ft = 'helm' },

  -- Status updates for LSP showing on the right
  { 'j-hui/fidget.nvim', opts = {} },

  -- Show css colors for strings
  { 'brenoprata10/nvim-highlight-colors', opts = {} },

  -- additional lua configuration, for plugins development
  { 'folke/neoconf.nvim', opts = {} },
  {
    'folke/lazydev.nvim',
    ft = 'lua', -- only load on lua files
    opts = {
      library = {
        'lazy.nvim',
        -- See the configuration section for more details
        -- Load luvit types when the `vim.uv` word is found
        { path = 'luvit-meta/library', words = { 'vim%.uv' } },
      },
    },
  },
  { 'Bilal2453/luvit-meta', lazy = true }, -- optional `vim.uv` typings

  -- Scala metals
  'scalameta/nvim-metals',
  -- my ZIO helper plugin
  { 'alisiikh/nvim-scala-zio-quickfix', dev = true, opts = {} },

  -- rust support
  { 'mrcjkb/rustaceanvim', version = '^4', lazy = false, ft = { 'rust' } },
  { 'saecki/crates.nvim', opts = {}, ft = { 'rust', 'toml' } },

  -- debugging
  {
    'mfussenegger/nvim-dap',
    dependencies = {
      { 'theHamsta/nvim-dap-virtual-text' },
      { 'rcarriga/nvim-dap-ui' },
      { 'jbyuki/one-small-step-for-vimkind' }, -- debug lua
      { 'leoluz/nvim-dap-go' }, -- debug go
      { 'mxsdev/nvim-dap-vscode-js' }, -- debug js
      { 'mfussenegger/nvim-dap-python' }, -- debug python
    },
  },

  -- fuzzy Finder (files, lsp, etc)
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
      'nvim-telescope/telescope-dap.nvim',
      'nvim-telescope/telescope-ui-select.nvim',
    },
  },

  -- treesitter: highlight, edit, and navigate code
  {
    'nvim-treesitter/nvim-treesitter',
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
      'nvim-treesitter/nvim-treesitter-context',
    },
    config = function()
      -- NOTE: update treesitter queries / highlights / etc on startup
      vim.cmd([[TSUpdateSync]])
    end,
  },

  -- unofficial Copilot plugin
  {
    'zbirenbaum/copilot.lua',
    event = 'InsertEnter',
    cmd = 'Copilot',
    config = function()
      require('copilot').setup({
        suggestion = {
          auto_trigger = true,
        },
      })
    end,
  },

  -- unofficial Codeium plugin
  -- {
  --   'Exafunction/codeium.nvim',
  --   event = 'InsertEnter',
  --   opts = {
  --     enable_chat = true,
  --   },
  -- },

  -- {
  --   'zbirenbaum/copilot-cmp',
  --   event = 'InsertEnter',
  --   opts = {},
  --   dependencies = {
  --     {
  --       'zbirenbaum/copilot.lua',
  --       opts = {
  --         -- author suggests to disable panel and suggestion if cmp plugin is used
  --         suggestion = { enabled = false },
  --         panel = { enabled = false },
  --       },
  --     },
  --   },
  -- },

  -- lualine copilot status
  { 'jonahgoldwastaken/copilot-status.nvim', lazy = true, event = 'BufReadPost' },

  -- discipline
  {
    'm4xshen/hardtime.nvim',
    dependencies = { 'MunifTanjim/nui.nvim', 'nvim-lua/plenary.nvim' },
    opts = {},
  },

  {
    'epwalsh/obsidian.nvim',
    version = '*', -- recommended, use latest release instead of latest commit
    lazy = true,
    ft = 'markdown',
    -- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
    -- event = {
    --   -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
    --   -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/**.md"
    --   "BufReadPre path/to/my-vault/**.md",
    --   "BufNewFile path/to/my-vault/**.md",
    -- },
    dependencies = {
      -- Required.
      'nvim-lua/plenary.nvim',

      -- see below for full list of optional dependencies 👇
    },
  },

  -- detect tabstop and shiftwidth automatically
  'tpope/vim-sleuth',

  -- multi-cursor selection ctrl+up/down - to add cursor, ctrl+n - select next word, shift-arrow - per char
  'mg979/vim-visual-multi',

  -- auto add closing bracket or closing quote
  { 'windwp/nvim-autopairs', opts = {} },

  -- surround text objects, ys - surround, ds - delete around, cs - change around
  {
    'kylechui/nvim-surround',
    version = '*',
    event = 'VeryLazy',
    opts = {},
  },

  -- smart join lines in blocks
  'Wansmer/treesj',

  -- useful plugin to show you pending keybinds.
  'folke/which-key.nvim',

  -- adds git releated signs to the gutter, as well as utilities for managing changes
  { 'lewis6991/gitsigns.nvim', opts = {} },

  -- add indentation function/class/etc context lines
  { 'lukas-reineke/indent-blankline.nvim', main = 'ibl', opts = {} },

  -- comments highlighting and navigation
  { 'folke/todo-comments.nvim' },

  -- markdown plugin
  {
    'iamcco/markdown-preview.nvim',
    cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
    ft = { 'markdown' },
    build = function()
      vim.fn['mkdp#util#install']()
    end,
  },

  -- neotest framework for running tests
  {
    'nvim-neotest/neotest',
    dependencies = {
      'nvim-neotest/nvim-nio',
      'nvim-neotest/neotest-plenary',
      'nvim-neotest/neotest-go',
      'nvim-neotest/neotest-python',
      { 'olisikh/neotest-scala', dev = true },
    },
  },
}, {
  lockfile = vim.fn.stdpath('data') .. '/lazy/lazy-lock.json',
  dev = {
    path = '~/Develop/nvim-plugins',
  },
  ui = {
    border = 'rounded',
  },
})
