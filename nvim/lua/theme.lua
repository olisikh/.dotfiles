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
