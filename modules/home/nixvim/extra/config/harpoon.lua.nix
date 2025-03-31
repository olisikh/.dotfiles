# lua
''
  local harpoon = require('harpoon')
  harpoon:setup({})

  local conf = require('telescope.config').values
  local function toggle_telescope(harpoon_files)
    local file_paths = {}
    for _, item in ipairs(harpoon_files.items) do
      table.insert(file_paths, item.value)
    end

    require('telescope.pickers')
      .new({}, {
        prompt_title = 'Harpoon',
        finder = require('telescope.finders').new_table({ results = file_paths }),
        previewer = conf.file_previewer({}),
        sorter = conf.generic_sorter({}),
      })
      :find()
  end

  vim.keymap.set('n', '<leader>hw', function() toggle_telescope(harpoon:list()) end, { desc = 'harpoon: Open harpoon window' })
  vim.keymap.set('n', '<leader>ht', function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = 'harpoon: Toggle quick menu' })
  vim.keymap.set('n', '<leader>ha', function() harpoon:list():add() end, { desc = 'harpoon: Add file to list' })
  vim.keymap.set('n', '<leader>1', function() harpoon:list():select(1) end, { desc = 'harpoon: Open file 1' })
  vim.keymap.set('n', '<leader>2', function() harpoon:list():select(2) end, { desc = 'harpoon: Open file 2' })
  vim.keymap.set('n', '<leader>3', function() harpoon:list():select(3) end, { desc = 'harpoon: Open file 3' })
  vim.keymap.set('n', '<leader>4', function() harpoon:list():select(4) end, { desc = 'harpoon: Open file 4' })
''
