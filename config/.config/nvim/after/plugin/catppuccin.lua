local catppuccin_flavour = vim.fn.getenv("CATPPUCCIN_FLAVOUR") or "macchiato"

require("catppuccin").setup({
  compile_path = vim.fn.stdpath "cache" .. "/catppuccin",
  flavour = catppuccin_flavour, -- latte, frappe, macchiato, mocha
  background = {
    light = "latte",
    dark = catppuccin_flavour,
  },
  no_italic = true,
  no_bold = true,
  term_colors = true,
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
        errors = { "italic" },
        hints = { "italic" },
        warnings = { "italic" },
        information = { "italic" },
      },
      underlines = {
        errors = { "underline" },
        hints = { "underline" },
        warnings = { "underline" },
        information = { "underline" },
      },
    },
  }
})

vim.cmd.colorscheme "catppuccin"
