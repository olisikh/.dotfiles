local nmap = require('user.utils').nmap

local trouble = require('trouble')

trouble.setup({})

nmap('<leader>xx', '<cmd>Trouble diagnostics toggle filter.buf=0<cr>', { desc = 'trouble: document diagnostics' })
nmap('<leader>xX', '<cmd>Trouble diagnostics toggle<cr>', { desc = 'trouble: workspace diagnostics' })
nmap('<leader>xl', '<cmd>Trouble loclist toggle<cr>', { desc = 'trouble: [l]oclist' })
nmap('<leader>xq', '<cmd>Trouble qflist toggle<cr>', { desc = 'trouble: [q]uickfix' })
