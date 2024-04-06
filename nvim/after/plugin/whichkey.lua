local which_key = require('which-key')

which_key.setup({
  spelling = {
    enabled = false,
  },
  window = {
    border = 'single',
  },
})

which_key.register({
  ['<leader>c'] = { name = '+Code' },
  ['<leader>s'] = { name = '+Search' },
  ['<leader>t'] = { name = '+Test' },
  ['<leader>x'] = { name = '+Trouble' },
})
