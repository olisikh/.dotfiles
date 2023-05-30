local mark = require('harpoon.mark')
local ui = require('harpoon.ui')

local function nmap(lhs, rhs, desc)
  if desc then desc = 'harpoon: ' .. desc end
  require('helpers').nmap(lhs, rhs, { desc = desc })
end

nmap('<leader>H', ui.toggle_quick_menu, 'toggle quick menu')
nmap('<leader>a', mark.add_file, 'add file')

for n = 4, 1, -1 do nmap('<leader>' .. n, function() ui.nav_file(n) end, 'jump file ' .. n) end
