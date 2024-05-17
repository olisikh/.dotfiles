local nmap = require('user.utils').nmap
local oil = require('oil')

oil.setup({})

nmap('-', oil.open, { desc = 'oil: open parent directory' })
nmap('_', function()
  oil.open(vim.uv.cwd())
end, { desc = 'oil: open cwd directory' })
