-- latte, frappe, macchiato, mocha
local flavour = vim.fn.getenv('CATPPUCCIN_FLAVOUR') or 'macchiato'



require('catppuccin').setup({
  compile_path = vim.fn.stdpath('cache') .. '/catppuccin',
  flavour = flavour,
  background = {
    light = 'latte',
    dark = flavour,
  },
  no_italic = false,
  no_bold = false,
  term_colors = false,
  dim_inactive = {
    enabled = true,
    shade = 'dark',
    percentage = 0.01,
  },
  styles = {
    comments = { 'italic' },
    conditionals = {},
    loops = {},
    functions = {},
    keywords = {},
    strings = {},
    variables = {},
    numbers = {},
    booleans = {},
    properties = {},
    types = {},
    operators = {},
  },
  integrations = {
    fidget = true,
    cmp = true,
    gitsigns = true,
    nvimtree = true,
    treesitter = true,
    telescope = true,
    dap = {
      enabled = true,
      enable_ui = true,
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
    },
  },
})

vim.cmd.colorscheme('catppuccin')
