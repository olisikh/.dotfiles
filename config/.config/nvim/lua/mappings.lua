local map = require("helpers").map

-- Make sure Space is not mapped to anything, used as leader key
map({ 'n', 'v' }, '<Space>', '<nop>', { silent = true })
map('n', '<esc>', '<nop>', { silent = true })

-- Shift Q to do nothing, avoid weirdness
map('n', 'Q', '<nop>')

-- Save work and quit
map('n', '<C-q>', ':wqa<CR>', { desc = 'save & quit' })

-- Remap for dealing with word wrap
map('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
map('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Join lines together
map('n', 'J', 'mzJ`z', { desc = 'join lines' })

-- Move things between statements
map('v', 'J', ":m '>+1<CR>gv=gv", { desc = 'move selection down btw statements' })
map('v', 'K', ":m '<-2<CR>gv=gv", { desc = 'move selection up btw statements' })

-- Keep cursor in the middle when moving half page up/down
map('n', '<C-d>', '<C-d>zz', { desc = 'jump half page down' })
map('n', '<C-u>', '<C-u>zz', { desc = 'jump half page up' })

-- Cursor in the middle during searches
map('n', 'n', 'nzzzv', { desc = 'jump to next match item' })
map('n', 'N', 'Nzzzv', { desc = 'jump to prev match item' })

-- Paste the text and keep it in clipboard while pasting
map('x', '<leader>p', "\"_dP", { desc = 'paste keeping the clipboard' })

-- copy into system clipboard, (useful for copying outside of vim context)
map({ 'n', 'v' }, '<leader>y', "\"+y", { desc = 'copy to blackhole register' })
map('n', '<leader>Y', "\"+Y", { desc = 'copy line to blackhole register' })
map({ 'n', 'v' }, '<leader>d', "\"_d", { desc = 'cut to blackhole register' })


-- Diagnostic keymaps
map("n", "[d", vim.diagnostic.goto_prev, { desc = 'diagnostic: prev error msg' })
map("n", "]d", vim.diagnostic.goto_next, { desc = 'diagnostic: next error msg' })
map('n', '<leader>E', vim.diagnostic.open_float, { desc = "open floating diagnostic message" })
map('n', '<leader>q', vim.diagnostic.setloclist, { desc = "open diagnostics list" })
