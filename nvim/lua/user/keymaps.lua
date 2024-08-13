local uu = require('user.utils')
local map = uu.map
local nmap = uu.nmap

-- Make sure Space is not mapped to anything, used as leader key
map({ 'n', 'v' }, '<Space>', '<nop>', { silent = true })
map('n', '<esc>', '<nop>', { silent = true })

-- Shift Q to do nothing, avoid weirdness
map('n', 'Q', '<nop>')

-- Remap for dealing with word wrap
map('n', 'k', "v:count == 0 ? 'gk' : 'kzz'", { expr = true, silent = true })
map('n', 'j', "v:count == 0 ? 'gj' : 'jzz'", { expr = true, silent = true })

-- Join lines together
map('n', 'J', 'mzJ`z', { desc = 'join lines' })

-- Move things between statements
map('v', 'J', ":m '>+1<cr>gv=gv", { desc = 'move selection down between statements' })
map('v', 'K', ":m '<-2<cr>gv=gv", { desc = 'move selection up between statements' })

-- Keep cursor in the middle when moving half page up/down
-- map('n', '<C-d>', '<C-d>zz', { desc = 'jump half page down' })
-- map('n', '<C-u>', '<C-u>zz', { desc = 'jump half page up' })

-- Cursor in the middle during searches
map('n', 'n', 'nzzzv', { desc = 'jump to next match item' })
map('n', 'N', 'Nzzzv', { desc = 'jump to prev match item' })

-- Paste the text and keep it in clipboard while pasting
map('x', '<leader>p', '"_dP', { desc = 'paste keeping the clipboard' })

-- copy into system clipboard, (useful for copying outside of vim context)
map({ 'n', 'v' }, '<leader>y', '"+y', { desc = 'copy to blackhole register' })
map('n', '<leader>Y', '"+Y', { desc = 'copy line to blackhole register' })
map({ 'n', 'v' }, '<leader>d', '"_d', { desc = 'cut to blackhole register' })

-- Increase speed of window resize commande
nmap('<C-w>>', ':vertical resize +10<cr>', { noremap = true, silent = true })
nmap('<C-w><', ':vertical resize -10<cr>', { noremap = true, silent = true })
nmap('<C-w>+', ':horizontal resize +5<cr>', { noremap = true, silent = true })
nmap('<C-w>-', ':horizontal resize -5<cr>', { noremap = true, silent = true })

-- Shift line or block right and left
nmap('<Tab>', '>>', { noremap = true, silent = true })
nmap('<S-Tab>', '<<', { noremap = true, silent = true })
map('v', '<Tab>', '>gv', { noremap = true, silent = true })
map('v', '<S-Tab>', '<gv', { noremap = true, silent = true })

nmap('<leader>ig', ':CopilotToggle<cr>', { desc = 'copilot: Toggle Github copilot' })

-- nmap('<leader>ic', ':CodeiumToggle<cr>', { desc = 'codeium: Toggle Codeium' })
