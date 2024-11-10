-- latte, frappe, macchiato, mocha
local theme = 'catppuccin'
local themeStyle = vim.fn.getenv('THEME_STYLE')

require('catppuccin').setup({
  compile_path = vim.fn.stdpath('cache') .. '/catppuccin',
  dim_inactive = {
    enabled = false,
  },
  transparent_background = true,
  default_integrations = true,
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

require('lualine').setup({
  options = {
    theme = theme,
  },
  sections = {
    lualine_c = {
      'filename',
    },
    lualine_x = {
      'harpoon2',
      copilot_status,
      {
        function()
          -- nf-md-robot hacker font icon
          local status = require('ollama').status()
          if not status then
            return '󱙻 '
          end

          if status == 'WORKING' then
            return '󱚣 '
          else
            return '󱙺 '
          end
        end,
        cond = function()
          return package.loaded['ollama'] and require('ollama').status() ~= nil
        end,
      },
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
