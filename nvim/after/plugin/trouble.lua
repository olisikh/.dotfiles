local nmap = require('user.utils').nmap

local trouble = require('trouble')

trouble.setup({})

nmap('<leader>xx', ':TroubleToggle<cr>', { desc = 'trouble: toggle' })
nmap('<leader>xw', ':TroubleToggle workspace_diagnostics<cr>', { desc = 'trouble: [w]orkspace diagnostics' })
nmap('<leader>xd', ':TroubleToggle document_diagnostics<cr>', { desc = 'trouble: [d]ocument diagnostics' })
nmap('<leader>xl', ':TroubleToggle loclist<cr>', { desc = 'trouble: [l]oclist' })
nmap('<leader>xq', ':TroubleToggle quickfix<cr>', { desc = 'trouble: [q]uickfix' })
