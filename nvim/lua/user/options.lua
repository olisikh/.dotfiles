vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Globally enable/disable inlay hints
vim.g.inlayhints = false

vim.diagnostic.config({
  virtual_text = true,
})

local opt = function(scope, key, value)
  local s = { o = vim.o, opt = vim.opt, b = vim.bo, w = vim.wo }
  s[scope][key] = value
  if scope ~= 'o' then
    s['o'][key] = value
  end
end

-- See `:help vim.o`
-- Highlight cursor line
opt('o', 'cursorline', true)
-- Set line width marker at 120 characters per line
opt('opt', 'colorcolumn', '121')
-- Keep cursor always in the middle when possible
opt('o', 'scrolloff', 8)

opt(
  'opt',
  'guicursor',
  'n-v-c:block-Cursor/lCursor-blinkon0,i-ci-ve:ver25,r-cr:hor20,o:hor50,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor,sm:block-blinkwait175-blinkoff150-blinkon175'
)

-- Set highlight on search
opt('o', 'hlsearch', false)

-- Make line numbers default
opt('o', 'number', true)
opt('o', 'relativenumber', true)

-- indentation

-- Enable mouse mode
opt('o', 'mouse', 'a')

-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
opt('o', 'clipboard', 'unnamedplus')

-- Enable break indent
opt('o', 'breakindent', true)

-- Save undo history
opt('o', 'swapfile', false)
opt('o', 'backup', false)
opt('o', 'undofile', true)
opt('o', 'undodir', os.getenv('HOME') .. '/.vim/undodir')
opt('o', 'viewdir', os.getenv('HOME') .. '/.vim/viewdir')

-- Smart indentation (whitespaces keep their relative indentation)
opt('o', 'autoindent', true)
opt('o', 'smartindent', true)
opt('o', 'indentexpr', '')
opt('o', 'backspace', 'indent,eol,start')
opt('o', 'tabstop', 2)
opt('o', 'shiftwidth', 2)
opt('o', 'expandtab', true)

-- Case insensitive searching UNLESS /C or capital in search
opt('o', 'ignorecase', true)
opt('o', 'smartcase', true)

-- Keep signcolumn on by default
opt('w', 'signcolumn', 'yes')

-- Decrease update time
opt('o', 'updatetime', 250)
opt('o', 'timeout', true)
opt('o', 'timeoutlen', 300)

-- Set completeopt to have a better completion experience
opt('o', 'completeopt', 'menu,menuone,noinsert')

opt('o', 'termguicolors', true)

-- avoid excessive messages
vim.opt.shortmess:append('c')
vim.opt.shortmess:remove('F')
