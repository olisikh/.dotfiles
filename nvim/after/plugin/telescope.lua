local nmap = require('helpers').nmap

local telescope = require('telescope')
local telescope_themes = require('telescope.themes')
local telescope_builtin = require('telescope.builtin')

-- [[ Configure Telescope ]]
-- See `:help telescope` and `:help telescope.setup()`
telescope.setup({
  defaults = {
    mappings = {
      i = {
        ['<C-u>'] = false,
        ['<C-d>'] = false,
      },
    },
  },
  extensions = {
    ['ui-select'] = {
      telescope_themes.get_dropdown({}),
    },
    frecency = {
      db_safe_mode = false,
      auto_validate = true,
    },
  },
})

-- Enable telescope fzf native, if installed
pcall(telescope.load_extension, 'fzf')
pcall(telescope.load_extension, 'dap')
pcall(telescope.load_extension, 'frecency')
pcall(telescope.load_extension, 'ui-select')

-- Telescope key mappings
nmap('<leader>?', telescope_builtin.oldfiles, { desc = 'find recently opened files' })
nmap('<leader><space>', telescope_builtin.buffers, { desc = 'find existing buffers' })
nmap('<leader>/', function()
  telescope_builtin.current_buffer_fuzzy_find(telescope_themes.get_dropdown({ winblend = 10, previewer = false }))
end, { desc = 'fuzzy find in current buffer' })

nmap('<leader>sf', telescope_builtin.git_files, { desc = '[s]earch [f]iles' })
nmap('<leader>sr', telescope.extensions.frecency.frecency, { desc = '[s]earch [r]ecent files' })
nmap('<leader>sp', telescope_builtin.find_files, { desc = '[s]earch [p]roject files' })
nmap('<leader>sh', telescope_builtin.help_tags, { desc = '[s]earch [h]elp' })
nmap('<leader>sw', telescope_builtin.grep_string, { desc = '[s]earch current [w]ord' })
nmap('<leader>sg', telescope_builtin.live_grep, { desc = '[s]earch by [g]rep' })
nmap('<leader>sd', telescope_builtin.diagnostics, { desc = '[s]earch [d]iagnostics' })
nmap('<leader>sk', telescope_builtin.keymaps, { desc = '[s]earch [k]eymaps' })
