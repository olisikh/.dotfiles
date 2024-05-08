local nmap = require('utils').nmap
local oil = require('oil')

oil.setup()

nmap('-', '<CMD>Oil<CR>', { desc = 'Open parent directory' })
