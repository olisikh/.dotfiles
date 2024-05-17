local nmap = require('user.utils').nmap

local trouble = require('trouble')

trouble.setup({})

nmap('<leader>xx', trouble.toggle, { desc = 'trouble: toggle' })
nmap('<leader>xw', function()
  trouble.toggle({ mode = 'workspace_diagnostics' })
end, { desc = 'trouble: [w]orkspace diagnostics' })
nmap('<leader>xd', function()
  trouble.toggle({ mode = 'document_diagnostics' })
end, { desc = 'trouble: [d]ocument diagnostics' })
nmap('<leader>xl', function()
  trouble.toggle({ mode = 'loclist' })
end, { desc = 'trouble: [l]oclist' })
nmap('<leader>xq', function()
  trouble.toggle({ mode = 'quickfix' })
end, { desc = 'trouble: [q]uickfix' })

nmap('<leader>xh', trouble.help, { desc = 'trouble: [h]elp' })
