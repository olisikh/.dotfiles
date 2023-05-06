local gpt = require('chatgpt')

gpt.setup({
  chat = {
    keymaps = {
      close = "<Esc>",
      yank_last = "<C-y>",
      scroll_up = "<C-u>",
      scroll_down = "<C-d>",
      toggle_settings = "<C-o>",
      new_session = "<C-n>",
      cycle_windows = "<Tab>",
    },
  },
  popup_input = {
    submit = { "<C-s>", "<C-Enter>" },
  },
})


local map = require('helpers').map

map('n', '<leader>gg', gpt.openChat, { desc = 'gpt: open chat' })
map('v', '<leader>ge', gpt.edit_with_instructions, { desc = 'gpt: edit with instructions' })
map('n', '<leader>ga', gpt.selectAwesomePrompt, { desc = 'gpt: act as' })
