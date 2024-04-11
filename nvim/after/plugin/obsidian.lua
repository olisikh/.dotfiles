local vault_path = vim.fn.getenv('OBSIDIAN_VAULT')

if vault_path == vim.NIL then
  vault_path = '~/Obsidian'
end

require('obsidian').setup({
  workspaces = {
    {
      name = 'personal',
      path = vault_path,
    },
  },
})
