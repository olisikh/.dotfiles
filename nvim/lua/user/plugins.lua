require('lazy').setup({
  -- catppuccin theme
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    lazy = false,
    priority = 1000,
  },

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
      { '<leader>gg', '<cmd>LazyGit<cr>', desc = 'git: Open [l]azygit' },
      { '<leader>gf', '<cmd>LazyGitCurrentFile<cr>', desc = 'git: [c]urrent file' },
      -- { '<leader>gf', '<cmd>LazyGitFilter<cr>', desc = 'git: [f]ilter' },
      -- { '<leader>gF', '<cmd>LazyGitFilterCurrentFile<cr>', desc = 'git: [F]ilter current file' },
    },
  },

  -- git blame plugin
  {
    'FabijanZulj/blame.nvim',
    cmd = { 'BlameToggle' },
    opts = {},
    keys = {
      { '<leader>gb', '<cmd>BlameToggle<cr>', desc = 'git: [b]lame window' },
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

  {
    'saghen/blink.cmp',
    -- optional: provides snippets for the snippet source
    dependencies = { 'rafamadriz/friendly-snippets' },

    -- use a release tag to download pre-built binaries
    version = '*',
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
  {
    'j-hui/fidget.nvim',
    opts = {
      -- disable black background, good for transparent background
      notification = {
        window = {
          winblend = 0,
        },
      },
    },
  },

  -- Highlight color strings
  { 'norcalli/nvim-colorizer.lua', opts = {} },

  -- additional lua configuration, for plugins development
  { 'folke/neoconf.nvim', opts = {} },
  {
    'folke/lazydev.nvim',
    dependencies = {
      { 'Bilal2453/luvit-meta', lazy = true }, -- optional `vim.uv` typings
    },
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

  -- Java
  { 'mfussenegger/nvim-jdtls', dependencies = { 'mfussenegger/nvim-dap' } },

  -- rust support
  {
    'mrcjkb/rustaceanvim',
    version = '^4',
    lazy = false,
    ft = { 'rust' },
  },
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

  -- ollama https://github.com/nomnivore/ollama.nvim
  {
    'nomnivore/ollama.nvim',
    cmd = { 'Ollama', 'OllamaModel', 'OllamaServe', 'OllamaServeStop' },
    keys = {
      {
        '<leader>ip',
        ':<c-u>lua require("ollama").prompt()<cr>',
        mode = { 'n', 'v' },
        desc = 'ollama: select prompt',
      },
      {
        '<leader>im',
        ':OllamaModel<cr>',
        mode = 'n',
        desc = 'ollama: choose model',
      },
    },
    opts = {
      model = 'codestral',
      serve = {
        on_start = true, -- start ollama server on plugin load
      },
    },
  },

  -- lualine copilot status
  { 'jonahgoldwastaken/copilot-status.nvim', lazy = true, event = 'BufReadPost' },

  -- discipline
  {
    'm4xshen/hardtime.nvim',
    dependencies = { 'MunifTanjim/nui.nvim' },
    opts = {},
  },

  {
    'MeanderingProgrammer/render-markdown.nvim',
    ft = 'markdown',
    lazy = true,
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
    ft = 'markdown',
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
      'marilari88/neotest-vitest',
      { 'olisikh/neotest-scala', dev = true },
    },
  },
}, {
  lockfile = vim.fn.stdpath('data') .. '/lazy/lazy-lock.json',
  dev = {
    path = '~/Develop/nvim-plugins',
  },
  install = {
    -- try to load one of these colorschemes when starting an installation during startup
    colorscheme = { 'catppuccin-mocha' },
  },
  ui = {
    border = 'rounded',
  },
})
