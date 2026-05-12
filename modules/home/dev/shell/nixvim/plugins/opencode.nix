{ ... }:
{
  plugins.opencode = {
    enable = true;
    settings = { };
  };

  extraConfigLua = # lua
    ''
      local opencode = require('opencode')
      local function opts(desc, extra)
        return vim.tbl_extend('force', { desc = desc, silent = true, remap = false }, extra or {})
      end

      vim.keymap.set('n', '<leader>oa', function() opencode.ask('@this: ', { submit = true }) end, opts('opencode: ask'))
      vim.keymap.set('n', '<leader>oc', function() opencode.select() end, opts('opencode: commands'))
      vim.keymap.set('n', '<leader>ot', function() opencode.toggle() end, opts('opencode: toggle'))
      vim.keymap.set({ 'x', 'n', 'v' }, 'go', function() return opencode.operator('@this ') end, opts('opencode: add range', { expr = true }))

      vim.keymap.set('n', '<S-C-u>', function() opencode.command('session.half.page.up') end, opts('opencode: half page up'))
      vim.keymap.set('n', '<S-C-d>', function() opencode.command('session.half.page.down') end, opts('opencode: half page down'))
        
      vim.g.opencode_opts = {
        -- NOTE: provide any special configuration here
      }
    '';
}
