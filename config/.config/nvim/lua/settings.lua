vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

local opt = require('helpers').opt

-- Keep cursor always in the middle when possible
opt('o', 'so', 999)

-- See `:help vim.o`
-- Set highlight on search
opt('o', 'hlsearch', false)

-- Make line numbers default
opt('o', 'number', true)
opt('o', 'relativenumber', true)

-- Enable mouse mode
opt('o', 'mouse', 'a')

-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
opt('o', 'clipboard', 'unnamedplus')

-- Enable break indent
opt('o', 'breakindent', true)

-- Save undo history
opt('o', 'undofile', true)

-- Smart indentation (whitespaces keep their relative indentation)
opt('o', 'autoindent', true)
opt('o', 'smartindent', true)
opt('o', 'indentexpr', '')
opt('o', 'backspace', 'indent,eol,start')

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
opt('o', 'completeopt', 'menuone,noinsert,noselect')

-- NOTE: You should make sure your terminal supports this
opt('o', 'termguicolors', true)

-- avoid excessive messages
vim.opt.shortmess:append('c')
vim.opt.shortmess:remove('F')
