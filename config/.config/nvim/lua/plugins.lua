return require('lazy').setup({
	-- Catppuccin theme
	{ 'catppuccin/nvim',                name = 'catppuccin' },

	-- tmux integration plugin
	{ 'christoomey/vim-tmux-navigator', lazy = false },

	-- Git related pluginss
	'tpope/vim-fugitive',
	'tpope/vim-rhubarb',

	-- File tree explorer
	'nvim-tree/nvim-tree.lua',
	'nvim-tree/nvim-web-devicons',

	{ 'folke/trouble.nvim',       dependencies = { 'nvim-tree/nvim-web-devicons' } },

	'theprimeagen/harpoon',
	'mbbill/undotree',

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

	-- Codeium, interactive AI autocomplete
	{
		'jcdickinson/codeium.nvim',
		dependencies = {
			'nvim-lua/plenary.nvim',
			'hrsh7th/nvim-cmp',
		},
		opts = {},
	},

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

	-- Autocompletion
	{
		'hrsh7th/nvim-cmp',
		dependencies = { 'hrsh7th/cmp-nvim-lsp', 'L3MON4D3/LuaSnip', 'saadparwaiz1/cmp_luasnip' },
	},
	-- Nice icons in cmp
	'onsails/lspkind-nvim',

	-- required by most plugins
	'nvim-lua/plenary.nvim',

	-- Detect tabstop and shiftwidth automatically
	'tpope/vim-sleuth',

	-- Multi-line selection (do I really need it?) CTRL+N select word
	'mg979/vim-visual-multi',

	-- Auto add closing bracket or closing quote
	{
		'windwp/nvim-autopairs',
		opts = {},
	},

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
	{
		'Wansmer/treesj',
		keys = {
			{ 'U', '<cmd>TSJToggle<cr>', desc = 'treesj: toggle' },
		},
		dependencies = { 'nvim-treesitter/nvim-treesitter' },
		opts = {
			{ use_default_keymaps = false },
		},
	},

	-- Scroll bar on the right to show your posiiton in the file
	{
		'gen740/SmoothCursor.nvim',
		opts = {
			autostart = true,
			linehl = 'cursorline',
		},
	},

	-- NOTE: This is where your plugins related to LSP can be installed.
	--  The configuration is done below. Search for lspconfig to find it below.
	{
		-- LSP Configuration & Plugins
		'neovim/nvim-lspconfig',
		dependencies = {
			-- Automatically install LSPs to stdpath for neovim
			{ 'williamboman/mason.nvim', opts = {} },
			{
				'williamboman/mason-lspconfig.nvim',
			},
			{
				'jay-babu/mason-null-ls.nvim',
				version = 'v1.2.0',
				event = { 'BufReadPre', 'BufNewFile' },
				dependencies = {
					{ 'jose-elias-alvarez/null-ls.nvim', opts = {} },
				},
				opts = {
					ensure_installed = {
						'prettier',
						'stylua',
						'rustfmt',
					},
					handlers = {
						stylua = function(source_name, methods)
							local null_ls = require('null-ls')
							null_ls.register(null_ls.builtins.formatting.stylua)
						end,
						prettier = function(source_name, methods)
							local null_ls = require('null-ls')
							null_ls.register(null_ls.builtins.formatting.prettier)
						end,
					},
				},
			},

			{
				'jay-babu/mason-nvim-dap.nvim',
				opts = {
					ensure_installed = {
						'codelldb',
						'js-debug-adapter',
					},
				},
			},

			-- Useful status updates for LSP
			{ 'j-hui/fidget.nvim',       opts = {} },

			-- Additional lua configuration, makes nvim stuff amazing!
			{
				'folke/neodev.nvim',
				opts = {
					library = {
						plugins = {
							'nvim-dap-ui',
						},
						types = true,
					},
				},
			},
		},
	},

	-- debugging
	{
		'mfussenegger/nvim-dap',
		dependencies = {
			{ 'theHamsta/nvim-dap-virtual-text',  opts = {} },
			{ 'rcarriga/nvim-dap-ui' },
			{ 'jbyuki/one-small-step-for-vimkind' },
			{ 'mxsdev/nvim-dap-vscode-js' },
			-- {
			-- 	"microsoft/vscode-js-debug",
			-- 	-- TODO: fix this installation, it's not working
			-- 	build = "npm install --legacy-peer-deps && npx gulp vsDebugServerBundle && mv dist out"
			-- },
		},
	},

	-- Scala metals
	'scalameta/nvim-metals',

	{ 'simrat39/rust-tools.nvim', ft = 'rust' },
	{ 'saecki/crates.nvim',       opts = {},                                       ft = { 'rust', 'toml' } },

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
		event = 'BufRead',
		dependencies = { 'nvim-lua/plenary.nvim' },
		opts = {},
	},

	'vim-test/vim-test',

	-- Fuzzy Finder (files, lsp, etc)
	{ 'nvim-telescope/telescope.nvim', version = '*' },

	-- Fuzzy Finder Algorithm which requires local dependencies to be built.
	-- Only load if `make` is available. Make sure you have the system
	-- requirements installed.
	{
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
		config = function()
			require('telescope').load_extension('frecency')
		end,
		dependencies = { 'kkharji/sqlite.lua' },
	},
	'nvim-telescope/telescope-dap.nvim',

	{
		-- Highlight, edit, and navigate code
		'nvim-treesitter/nvim-treesitter',
		dependencies = { 'nvim-treesitter/nvim-treesitter-textobjects' },
		config = function()
			pcall(require('nvim-treesitter.install').update({ with_sync = true }))
		end,
	},

	{
		'nvim-treesitter/nvim-treesitter-context',
		dependencies = { 'nvim-treesitter/nvim-treesitter' },
		opts = {},
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
}, {})
