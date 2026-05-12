{ ... }:
{
  plugins.smart-splits.enable = true;

  keymaps = [
    {
      key = "<A-h>";
      action = ":lua require('smart-splits').resize_left()<cr>";
      mode = "n";
      options = {
        silent = true;
        noremap = true;
        desc = "window: Resize split left";
      };
    }
    {
      key = "<A-j>";
      action = ":lua require('smart-splits').resize_down()<cr>";
      mode = "n";
      options = {
        silent = true;
        noremap = true;
        desc = "window: Resize split down";
      };
    }
    {
      key = "<A-k>";
      action = ":lua require('smart-splits').resize_up()<cr>";
      mode = "n";
      options = {
        silent = true;
        noremap = true;
        desc = "window: Resize split up";
      };
    }
    {
      key = "<A-l>";
      action = ":lua require('smart-splits').resize_right()<cr>";
      mode = "n";
      options = {
        silent = true;
        noremap = true;
        desc = "window: Resize split right";
      };
    }
    {
      key = "<C-h>";
      action = ":lua require('smart-splits').move_cursor_left()<cr>";
      mode = "n";
      options = {
        silent = true;
        noremap = true;
        desc = "window: jump left";
      };
    }
    {
      key = "<C-j>";
      action = ":lua require('smart-splits').move_cursor_down()<cr>";
      mode = "n";
      options = {
        silent = true;
        noremap = true;
        desc = "window: jump down";
      };
    }
    {
      key = "<C-k>";
      action = ":lua require('smart-splits').move_cursor_up()<cr>";
      mode = "n";
      options = {
        silent = true;
        noremap = true;
        desc = "window: jump up";
      };
    }
    {
      key = "<C-l>";
      action = ":lua require('smart-splits').move_cursor_right()<cr>";
      mode = "n";
      options = {
        silent = true;
        noremap = true;
        desc = "window: jump right";
      };
    }
    {
      key = "<leader><leader>h";
      action = ":lua require('smart-splits').swap_buf_left()<cr>";
      mode = "n";
      options = {
        silent = true;
        noremap = true;
        desc = "window: swap buffer left";
      };
    }
    {
      key = "<leader><leader>j";
      action = ":lua require('smart-splits').swap_buf_down()<cr>";
      mode = "n";
      options = {
        silent = true;
        noremap = true;
        desc = "window: swap buffer down";
      };
    }
    {
      key = "<leader><leader>k";
      action = ":lua require('smart-splits').swap_buf_up()<cr>";
      mode = "n";
      options = {
        silent = true;
        noremap = true;
        desc = "window: swap buffer up";
      };
    }
    {
      key = "<leader><leader>l";
      action = ":lua require('smart-splits').swap_buf_right()<cr>";
      mode = "n";
      options = {
        silent = true;
        noremap = true;
        desc = "window: swap buffer right";
      };
    }
  ];
}
