-- latte, frappe, macchiato, mocha
local theme = vim.fn.getenv('THEME')
local themeStyle = vim.fn.getenv('THEME_STYLE')

require('catppuccin').setup({
  compile_path = vim.fn.stdpath('cache') .. '/catppuccin',
  no_italic = false,
  no_bold = false,
  no_underline = false,
  term_colors = false,
  dim_inactive = {
    enabled = false,
    -- shade = 'dark',
    -- percentage = 0.01,
  },
  styles = {
    comments = { 'italic' },
    -- conditionals = {},
    -- loops = {},
    -- functions = {},
    -- keywords = {},
    -- strings = {},
    -- variables = {},
    -- numbers = {},
    -- booleans = {},
    -- properties = {},
    -- types = {},
    -- operators = {},
  },
  integrations = {
    fidget = true,
    cmp = true,
    gitsigns = true,
    nvimtree = true,
    neotest = true,
    treesitter = true,
    treesitter_context = true,
    telescope = {
      enabled = true,
      -- style = "nvchad"
    },
    lsp_trouble = true,
    harpoon = true,
    mason = true,
    notify = true,
    which_key = true,
    dap = true,
    dap_ui = true,
    markdown = true,
    indent_blankline = {
      enabled = true,
      -- scope_color = '', -- catppuccin color (eg. `lavender`) Default: text
      colored_indent_levels = false,
    },
    native_lsp = {
      enabled = true,
      virtual_text = {
        errors = { 'italic' },
        hints = { 'italic' },
        warnings = { 'italic' },
        information = { 'italic' },
      },
      underlines = {
        errors = { 'underline' },
        hints = { 'underline' },
        warnings = { 'underline' },
        information = { 'underline' },
      },
      inlay_hints = {
        background = false,
      },
    },
  },
})

require('eldritch').setup({
  -- your configuration comes here
  -- or leave it empty to use the default settings
  transparent = false, -- Enable this to disable setting the background color
  terminal_colors = true, -- Configure the colors used when opening a `:terminal` in [Neovim](https://github.com/neovim/neovim)
  styles = {
    -- Style to be applied to different syntax groups
    -- Value is any valid attr-list value for `:help nvim_set_hl`
    comments = { italic = true },
    keywords = { italic = true },
    functions = {},
    variables = {},
    -- Background styles. Can be "dark", "transparent" or "normal"
    sidebars = 'dark', -- style for sidebars, see below
    floats = 'dark', -- style for floating windows
  },
  sidebars = { 'qf', 'help' }, -- Set a darker background on sidebar-like windows. For example: `["qf", "vista_kind", "terminal", "packer"]`
  hide_inactive_statusline = false, -- Enabling this option, will hide inactive statuslines and replace them with a thin border instead. Should work with the standard **StatusLine** and **LuaLine**.
  dim_inactive = false, -- dims inactive windows, transparent must be false for this to work
  lualine_bold = true, -- When `true`, section headers in the lualine theme will be bold

  --- You can override specific color groups to use other groups or a hex color
  --- function will be called with a ColorScheme table
  ---@param colors ColorScheme
  -- on_colors = function(colors) end,

  --- You can override specific highlights to use other groups or a hex color
  --- function will be called with a Highlights and ColorScheme table
  ---@param highlights Highlights
  ---@param colors ColorScheme
  -- on_highlights = function(highlights, colors) end,
})

require('tokyonight').setup({
  -- your configuration comes here
  -- or leave it empty to use the default settings
  light_style = 'day', -- The theme is used when the background is set to light
  transparent = false, -- Enable this to disable setting the background color
  terminal_colors = true, -- Configure the colors used when opening a `:terminal` in [Neovim](https://github.com/neovim/neovim)
  styles = {
    -- Style to be applied to different syntax groups
    -- Value is any valid attr-list value for `:help nvim_set_hl`
    comments = { italic = true },
    keywords = { italic = true },
    functions = {},
    variables = {},
    -- Background styles. Can be "dark", "transparent" or "normal"
    sidebars = 'dark', -- style for sidebars, see below
    floats = 'dark', -- style for floating windows
  },
  sidebars = { 'qf', 'help' }, -- Set a darker background on sidebar-like windows. For example: `["qf", "vista_kind", "terminal", "packer"]`
  day_brightness = 0.3, -- Adjusts the brightness of the colors of the **Day** style. Number between 0 and 1, from dull to vibrant colors
  hide_inactive_statusline = false, -- Enabling this option, will hide inactive statuslines and replace them with a thin border instead. Should work with the standard **StatusLine** and **LuaLine**.
  dim_inactive = false, -- dims inactive windows
  lualine_bold = false, -- When `true`, section headers in the lualine theme will be bold

  --- You can override specific color groups to use other groups or a hex color
  --- function will be called with a ColorScheme table
  ---@param colors ColorScheme
  -- on_colors = function(colors) end,

  --- You can override specific highlights to use other groups or a hex color
  --- function will be called with a Highlights and ColorScheme table
  ---@param highlights Highlights
  ---@param colors ColorScheme
  -- on_highlights = function(highlights, colors) end,
})

local function copilot_status()
  return require('copilot_status').status_string()
end

local function codeium_status()
  local codeium = require('cmp').core:get_sources(function(source)
    return source.name == 'codeium'
  end)[1]

  if codeium == nil then
    return ' '
  elseif codeium.status == 2 then
    return ' '
  else
    return '󰘦 '
  end
end

require('lualine').setup({
  options = {
    theme = theme,

    -- section_separators = { left = '', right = '' },
    -- component_separators = { left = '', right = '' },
  },
  sections = {
    lualine_c = {
      'filename',
    },
    lualine_x = {
      'harpoon2',
      codeium_status,
      copilot_status,
      'encoding',
      'filetype',
    },
  },
})

if themeStyle ~= vim.NIL then
  vim.cmd.colorscheme(theme .. '-' .. themeStyle)
else
  vim.cmd.colorscheme(theme)
end
