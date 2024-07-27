local which_key = require('which-key')

which_key.setup({
  spelling = {
    enabled = false,
  },
  window = {
    border = 'single',
  },
})

which_key.add({
  { '<leader>c', group = 'Code' },
  { '<leader>s', group = 'Search' },
  { '<leader>t', group = 'Test' },
  { '<leader>x', group = 'Trouble' },
})
