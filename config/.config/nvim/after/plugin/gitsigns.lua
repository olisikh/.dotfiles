local gsigns = require('gitsigns')

gsigns.setup {
  signs = {
    add          = { text = '+' },
    change       = { text = '~' },
    changedelete = { text = '~' },
    delete       = { text = '_' },
    topdelete    = { text = '‾' },
  },
}
