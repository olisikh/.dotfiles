local todo_comments = require('todo-comments')
todo_comments.setup({})

-- Change icons for diagnostic signs too
local signs = { Error = ' ', Warn = ' ', Hint = ' ', Info = ' ' }
for type, icon in pairs(signs) do
  local hl = 'DiagnosticSign' .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

local nmap = require('utils').nmap
nmap('<leader>st', ':TodoTelescope<cr>', { desc = 'todo: [s]earch [t]odos' })
nmap('<leader>xt', ':TodoTrouble<cr>', { desc = 'trouble: [t]odos' })
