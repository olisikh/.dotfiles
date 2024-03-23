-- latte, frappe, macchiato, mocha
local flavour = vim.fn.getenv('CATPPUCCIN_FLAVOUR') or 'macchiato'

require('catppuccin').setup({
  compile_path = vim.fn.stdpath('cache') .. '/catppuccin',
  flavour = flavour,
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

require('lualine').setup({
  options = {
    theme = 'catppuccin',

    section_separators = { left = '', right = '' },
    component_separators = { left = '', right = '' },
  },
  sections = {
    lualine_x = { 'encoding', 'filetype' },
    lualine_c = { 'harpoon2' },
  },
})

vim.cmd.colorscheme('catppuccin')
