local nmap = require('helpers').nmap

nmap('<leader>u', vim.cmd.UndotreeToggle, { desc = 'open undo tree' })
