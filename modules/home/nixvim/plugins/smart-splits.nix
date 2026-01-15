{ ... }:
{
  plugins.smart-splits.enable = true;

  keymaps = [
    # vim.keymap.set('n', '<A-h>', s.resize_left)
    {
      key = "<A-h>";
      action = ":lua require('smart-splits').resize_left()<cr>";
      mode = "n";
    }
    # vim.keymap.set('n', '<A-j>', s.resize_down)
    {
      key = "<A-j>";
      action = ":lua require('smart-splits').resize_down()<cr>";
      mode = "n";
    }
    # vim.keymap.set('n', '<A-k>', s.resize_up)
    {
      key = "<A-k>";
      action = ":lua require('smart-splits').resize_up()<cr>";
      mode = "n";
    }
    # vim.keymap.set('n', '<A-l>', s.resize_right)
    {
      key = "<A-l>";
      action = ":lua require('smart-splits').resize_right()<cr>";
      mode = "n";
    }
    # -- moving between splits
    # vim.keymap.set('n', '<C-h>', s.move_cursor_left)
    {
      key = "<C-h>";
      action = ":lua require('smart-splits').move_cursor_left()<cr>";
      mode = "n";
      options = {
        silent = true;
        noremap = true;
      };
    }
    # vim.keymap.set('n', '<C-j>', s.move_cursor_down)
    {
      key = "<C-j>";
      action = ":lua require('smart-splits').move_cursor_down()<cr>";
      mode = "n";
      options = {
        silent = true;
        noremap = true;
      };
    }
    # vim.keymap.set('n', '<C-k>', s.move_cursor_up)
    {
      key = "<C-k>";
      action = ":lua require('smart-splits').move_cursor_up()<cr>";
      mode = "n";
      options = {
        silent = true;
        noremap = true;
      };
    }
    # vim.keymap.set('n', '<C-l>', s.move_cursor_right)
    {
      key = "<C-l>";
      action = ":lua require('smart-splits').move_cursor_right()<cr>";
      mode = "n";
      options = {
        silent = true;
        noremap = true;
      };
    }
    # vim.keymap.set('n', '<C-\\>', s.move_cursor_previous)
    # -- swapping buffers between windows
    # vim.keymap.set('n', '<leader><leader>h', s.swap_buf_left)
    {
      key = "<leader><leader>h";
      action = ":lua require('smart-splits').swap_buf_left()<cr>";
      mode = "n";
    }
    # vim.keymap.set('n', '<leader><leader>j', s.swap_buf_down)
    {
      key = "<leader><leader>j";
      action = ":lua require('smart-splits').swap_buf_down()<cr>";
      mode = "n";
    }
    # vim.keymap.set('n', '<leader><leader>k', s.swap_buf_up)
    {
      key = "<leader><leader>k";
      action = ":lua require('smart-splits').swap_buf_up()<cr>";
      mode = "n";
    }
    # vim.keymap.set('n', '<leader><leader>l', s.swap_buf_right)
    {
      key = "<leader><leader>l";
      action = ":lua require('smart-splits').swap_buf_right()<cr>";
      mode = "n";
    }
  ];
}
