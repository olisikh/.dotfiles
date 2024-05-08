local nmap = require('user.utils').nmap

nmap('<leader>u', vim.cmd.UndotreeToggle, { desc = 'open undo tree' })
