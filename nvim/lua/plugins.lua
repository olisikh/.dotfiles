require('lazy').setup({
  -- Catppuccin theme
  { 'catppuccin/nvim',                name = 'catppuccin' },
  -- Statusline plugin
  { 'feline-nvim/feline.nvim' },

  -- tmux integration plugin
  { 'christoomey/vim-tmux-navigator', lazy = false },

  -- required by most plugins
  'nvim-lua/plenary.nvim',

  -- Git related pluginss
  'tpope/vim-fugitive',
  'tpope/vim-rhubarb',

  -- File tree explorer
  'nvim-tree/nvim-tree.lua',
  -- Beautiful nerd font icons in nvim tree
  'nvim-tree/nvim-web-devicons',
  -- Beautiful nerd font icons in cmp
  'onsails/lspkind-nvim',

  -- Traverse diagnostics in a separate window
  'folke/trouble.nvim',

  'theprimeagen/harpoon',
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
    },
  },

  -- NOTE: This is where your plugins related to LSP can be installed.
  --  The configuration is done below. Search for lspconfig to find it below.
  {
    -- LSP Configuration & Plugins
    'neovim/nvim-lspconfig',
    dependencies = {
      -- Automatically install LSPs to stdpath for neovim
      { 'williamboman/mason.nvim',          opts = {} },
      { 'williamboman/mason-lspconfig.nvim' },
      {
        'jay-babu/mason-null-ls.nvim',
        event = { 'BufReadPre', 'BufNewFile' },
        dependencies = { 'jose-elias-alvarez/null-ls.nvim' },
      },

      {
        'jay-babu/mason-nvim-dap.nvim',
        dependencies = {
          'mfussenegger/nvim-dap',
        },
      },

      -- Useful status updates for LSP
      { 'j-hui/fidget.nvim',           opts = { window = { blend = 0 } } },

      -- Inlay hints
      { 'lvimuser/lsp-inlayhints.nvim' },

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
    },
  },

  -- Scala metals
  'scalameta/nvim-metals',

  -- Rust tools & others
  { 'simrat39/rust-tools.nvim', ft = 'rust' },
  { 'saecki/crates.nvim',       opts = {},  ft = { 'rust', 'toml' } },

  -- Debugging
  {
    'mfussenegger/nvim-dap',
    dependencies = {
      { 'theHamsta/nvim-dap-virtual-text' },
      { 'rcarriga/nvim-dap-ui' },
      { 'jbyuki/one-small-step-for-vimkind' }, -- debug lua
      { 'leoluz/nvim-dap-go' },                -- debug go
      { 'mxsdev/nvim-dap-vscode-js' },         -- debug js
    },
  },

  -- Fuzzy Finder (files, lsp, etc)
  {
    'nvim-telescope/telescope.nvim',
    version = '*',
    dependencies = {
      {
        -- Fuzzy Finder Algorithm which requires local dependencies to be built.
        -- Only load if `make` is available. Make sure you have the system
        -- requirements installed.
        'nvim-telescope/telescope-fzf-native.nvim',
        -- NOTE: If you are having trouble with this installation,
        --       refer to the README for telescope-fzf-native for more instructions.
        build = 'make',
        cond = function()
          return vim.fn.executable('make') == 1
        end,
      },
      {
        'nvim-telescope/telescope-frecency.nvim',
        dependencies = { 'kkharji/sqlite.lua' },
      },
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
      { "glepnir/lspsaga.nvim", event = "LspAttach", },
    },
    config = function()
      pcall(require('nvim-treesitter.install').update({ with_sync = true }))
    end,
  },

  -- Unofficial Codeium plugin, interactive AI autocomplete
  {
    'jcdickinson/codeium.nvim',
    event = 'InsertEnter',
    opts = {},
  },

  -- Github copilot, use :Copilot setup to configure
  -- {
  --   'zbirenbaum/copilot.lua',
  --   cmd = "Copilot",
  --   event = "InsertEnter",
  --   config = function()
  --     require("copilot").setup({
  --       suggestion = {
  --         enabled = true,
  --         auto_trigger = true,
  --         debounce = 0,
  --         keymap = {
  --           accept = "<C-g>",
  --         }
  --       },
  --       filetypes = {
  --         scala = true,
  --         lua = true
  --       }
  --     })
  --   end,
  -- },

  -- Official Codeium plugin, without cmp integration
  -- {
  --   'Exafunction/codeium.vim',
  --   config = function()
  --     -- Change '<C-g>' here to any keycode you like.
  --     vim.keymap.set('i', '<C-g>', function() return vim.fn['codeium#Accept']() end, { expr = true })
  --     vim.keymap.set('i', '<c-;>', function() return vim.fn['codeium#CycleCompletions'](1) end, { expr = true })
  --     vim.keymap.set('i', '<c-,>', function() return vim.fn['codeium#CycleCompletions'](-1) end, { expr = true })
  --     vim.keymap.set('i', '<c-x>', function() return vim.fn['codeium#Clear']() end, { expr = true })
  --   end
  -- },

  -- Detect tabstop and shiftwidth automatically
  'tpope/vim-sleuth',

  -- Multi-line selection (do I really need it?) CTRL+N select word
  'mg979/vim-visual-multi',

  -- Auto add closing bracket or closing quote
  { 'windwp/nvim-autopairs',   opts = {} },

  -- Surround text objects
  {
    'kylechui/nvim-surround',
    version = '*',
    event = 'VeryLazy',
    opts = {},
  },

  -- Jump to any char in the buffer using as few keystrokes as possible
  {
    'phaazon/hop.nvim',
    branch = 'v2',
    opts = {
      keys = 'etovxqpdygfblzhckisuran',
    },
  },

  -- Smart join lines in blocks
  'Wansmer/treesj',

  -- Useful plugin to show you pending keybinds.
  'folke/which-key.nvim',

  -- Adds git releated signs to the gutter, as well as utilities for managing changes
  'lewis6991/gitsigns.nvim',

  -- Add indentation function/class/etc context lines
  'lukas-reineke/indent-blankline.nvim',

  -- "gc" to comment visual regions/lines
  { 'numToStr/Comment.nvim',   opts = {} },

  --  comments highlighting and navigation
  { 'folke/todo-comments.nvim' },

  -- 'vim-test/vim-test',
  {
    -- Neotest framework for running tests
    'nvim-neotest/neotest',
    dependencies = {
      'nvim-neotest/neotest-plenary',
      'nvim-neotest/neotest-go',
      "stevanmilic/neotest-scala",
      'rouge8/neotest-rust',
    }
  },

  -- OpenAI ChatGPT
  {
    'jackMort/ChatGPT.nvim',
    event = 'VeryLazy',
    dependencies = {
      'MunifTanjim/nui.nvim',
    },
  },

  -- NOTE: Next Step on Your Neovim Journey: Add/Configure additional "plugins" for kickstart
  --       These are some example plugins that I've included in the kickstart repository.
  --       Uncomment any of the lines below to enable them.
  -- require 'kickstart.plugins.autoformat',
  -- require 'kickstart.plugins.debug',

  -- NOTE: The import below automatically adds your own plugins, configuration, etc from `lua/custom/plugins/*.lua`
  --    You can use this folder to prevent any conflicts with this init.lua if you're interested in keeping
  --    up-to-date with whatever is in the kickstart repo.
  --
  --    For additional information see: https://github.com/folke/lazy.nvim#-structuring-your-plugins
  --
  --    An additional note is that if you only copied in the `init.lua`, you can just comment this line
  --    to get rid of the warning telling you that there are not plugins in `lua/custom/plugins/`.
  -- { import = 'custom.plugins' },
}, {
  lockfile = vim.fn.stdpath("data") .. "/lazy/lazy-lock.json"
})
