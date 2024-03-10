local tree = require('nvim-tree')
local api = require('nvim-tree.api')

tree.setup({
  renderer = {
    icons = {
      git_placement = 'after',
    },
  },
  view = {
    width = 50,
  },
  git = {
    enable = true,
    ignore = true,
  },
  filters = { dotfiles = true },
  on_attach = function(bufnr)
    api.config.mappings.default_on_attach(bufnr)
  end,
})

local nmap = require('helpers').nmap

nmap('<leader>o', api.tree.toggle, { desc = 'nvim-tree: toggle', noremap = true })
nmap('<leader>O', ':NvimTreeFindFile<cr>', { desc = 'nvim-tree: locale file in a tree', noremap = true })
