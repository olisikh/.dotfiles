local mark = require('harpoon.mark')
local ui = require('harpoon.ui')

local function nmap(lhs, rhs, desc)
  if desc then
    desc = 'harpoon: ' .. desc
  end
  require('helpers').nmap(lhs, rhs, { desc = desc })
end

nmap('<leader>h', ui.toggle_quick_menu, 'toggle quick menu')
nmap('<leader>ha', mark.add_file, 'add file')
nmap('<leader>hH', ui.nav_prev, 'prev file')
nmap('<leader>hh', ui.nav_next, 'next file')
