{ ... }:
{
  plugins.smart-splits.enable = true;

  extraConfigLua = ''
    ;(function()
      local ss = require('smart-splits')

      local function wezterm_navigate(wez_dir)
        if not vim.env.WEZTERM_UNIX_SOCKET then return end
        local b64 = vim.base64.encode(wez_dir)
        io.write(('\027]1337;SetUserVar=%s=%s\007'):format('navigate_direction', b64))
        io.flush()
      end

      local function smart_move(nvim_dir, wez_dir)
        local before = vim.api.nvim_get_current_win()
        vim.cmd('wincmd ' .. nvim_dir)
        if vim.api.nvim_get_current_win() == before then
          wezterm_navigate(wez_dir)
        end
      end

      local map = vim.keymap.set

      -- move
      map('n', '<C-h>', function() smart_move('h', 'Left') end,  { silent = true, desc = 'window: jump left' })
      map('n', '<C-j>', function() smart_move('j', 'Down') end,  { silent = true, desc = 'window: jump down' })
      map('n', '<C-k>', function() smart_move('k', 'Up') end,    { silent = true, desc = 'window: jump up' })
      map('n', '<C-l>', function() smart_move('l', 'Right') end, { silent = true, desc = 'window: jump right' })

      -- resize
      map('n', '<A-h>', ss.resize_left,  { silent = true, desc = 'window: resize split left' })
      map('n', '<A-j>', ss.resize_down,  { silent = true, desc = 'window: resize split down' })
      map('n', '<A-k>', ss.resize_up,    { silent = true, desc = 'window: resize split up' })
      map('n', '<A-l>', ss.resize_right, { silent = true, desc = 'window: resize split right' })

      -- swap buffers
      map('n', '<leader><leader>h', ss.swap_buf_left,  { silent = true, desc = 'window: swap buffer left' })
      map('n', '<leader><leader>j', ss.swap_buf_down,  { silent = true, desc = 'window: swap buffer down' })
      map('n', '<leader><leader>k', ss.swap_buf_up,    { silent = true, desc = 'window: swap buffer up' })
      map('n', '<leader><leader>l', ss.swap_buf_right, { silent = true, desc = 'window: swap buffer right' })
    end)()
  '';
}
