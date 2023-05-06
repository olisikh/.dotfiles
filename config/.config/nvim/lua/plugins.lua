return require('lazy').setup({

  -- Catppuccin theme
  { "catppuccin/nvim",                name = "catppuccin" },


  -- tmux integration plugin
  { "christoomey/vim-tmux-navigator", lazy = false },

  -- Git related pluginss
  'tpope/vim-fugitive',
  'tpope/vim-rhubarb',

  -- File tree explorer
  'nvim-tree/nvim-tree.lua',
  'nvim-tree/nvim-web-devicons',

  {
    "folke/trouble.nvim",
    requires = "nvim-tree/nvim-web-devicons",
  },

  'theprimeagen/harpoon',
  'mbbill/undotree',

  -- Github copilot, use :Copilot setup to configure
  {
    'zbirenbaum/copilot.lua',
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({
        suggestion = {
          enabled = true,
          auto_trigger = true,
          debounce = 0,
          keymap = {
            accept = "<C-g>",
          }
        },
        filetypes = {
          scala = true,
          lua = true
        }
      })
    end,
  },

  {
    -- Autocompletion
    'hrsh7th/nvim-cmp',
    event = "InsertEnter",
    dependencies = { 'hrsh7th/cmp-nvim-lsp', 'L3MON4D3/LuaSnip', 'saadparwaiz1/cmp_luasnip' }
  },

  -- Scala metals
  {
    'scalameta/nvim-metals',
    dependencies = { "nvim-lua/plenary.nvim", "mfussenegger/nvim-dap" }
  },

  -- Detect tabstop and shiftwidth automatically
  'tpope/vim-sleuth',

  -- Multi-line selection
  'mg979/vim-visual-multi',

  -- Surround text objects
  {
    'kylechui/nvim-surround',
    version = "*",
    event = "VeryLazy",
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
  {
    'Wansmer/treesj',
    keys = {
      { "U", "<cmd>TSJToggle<cr>", desc = "treesj: toggle" },
    },
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    opts = {
      { use_default_keymaps = false },
    }
  },

  -- Scroll bar on the right to show your posiiton in the file
  {
    'gen740/SmoothCursor.nvim',
    opts = {
      autostart = true,
      linehl = 'cursorline',
    }
  },

  -- NOTE: This is where your plugins related to LSP can be installed.
  --  The configuration is done below. Search for lspconfig to find it below.
  {
    -- LSP Configuration & Plugins
    'neovim/nvim-lspconfig',
    dependencies = {
      -- Automatically install LSPs to stdpath for neovim
      { 'williamboman/mason.nvim',           opts = {} },
      { 'williamboman/mason-lspconfig.nvim', opts = { 'lua_ls', 'rust-analyzer' } },
      {
        'jay-babu/mason-null-ls.nvim',
        version = 'v1.2.0',
        opts = { 'prettier', 'stylua', 'rustfmt' }
      },

      { 'jay-babu/mason-nvim-dap.nvim', opts = { 'codelldb' } },

      -- Useful status updates for LSP
      { 'j-hui/fidget.nvim',            opts = {} },

      -- Additional lua configuration, makes nvim stuff amazing!
      {
        'folke/neodev.nvim',
        opts = {
          library = {
            plugins = {
              "nvim-dap-ui"
            },
            types = true
          }
        }
      },
    },
  },

  { 'theHamsta/nvim-dap-virtual-text', opts = {} },
  { "rcarriga/nvim-dap-ui",            dependencies = { "mfussenegger/nvim-dap" } },
  { 'simrat39/rust-tools.nvim',        ft = 'rust' },
  { 'saecki/crates.nvim',              opts = {},                                 ft = { 'rust', 'toml' } },


  -- Useful plugin to show you pending keybinds.
  'folke/which-key.nvim',

  -- Adds git releated signs to the gutter, as well as utilities for managing changes
  'lewis6991/gitsigns.nvim',

  -- Set lualine as statusline
  'nvim-lualine/lualine.nvim',

  {
    -- Add indentation guides even on blank lines
    'lukas-reineke/indent-blankline.nvim',
    -- Enable `lukas-reineke/indent-blankline.nvim`
    -- See `:help indent_blankline.txt`
    opts = {
      char = '┊',
      show_trailing_blankline_indent = false,
    },
  },

  -- "gc" to comment visual regions/lines
  { 'numToStr/Comment.nvim',         opts = {} },

  --  comments highlighting and navigation
  {
    'folke/todo-comments.nvim',
    event = "BufRead",
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = {},
  },

  'vim-test/vim-test',

  -- Fuzzy Finder (files, lsp, etc)
  { 'nvim-telescope/telescope.nvim', version = '*', dependencies = { 'nvim-lua/plenary.nvim' } },

  -- Fuzzy Finder Algorithm which requires local dependencies to be built.
  -- Only load if `make` is available. Make sure you have the system
  -- requirements installed.
  {
    'nvim-telescope/telescope-fzf-native.nvim',
    -- NOTE: If you are having trouble with this installation,
    --       refer to the README for telescope-fzf-native for more instructions.
    build = 'make',
    cond = function()
      return vim.fn.executable 'make' == 1
    end,
  },
  {
    "nvim-telescope/telescope-frecency.nvim",
    config = function()
      require("telescope").load_extension("frecency")
    end,
    dependencies = { "kkharji/sqlite.lua" }
  },

  {
    -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    dependencies = { 'nvim-treesitter/nvim-treesitter-textobjects', },
    config = function()
      pcall(require('nvim-treesitter.install').update { with_sync = true })
    end,
  },

  {
    'nvim-treesitter/nvim-treesitter-context',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    opts = {}
  },


  -- OpenAI ChatGPT
  {
    "jackMort/ChatGPT.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim"
    }
  }


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
}, {})
