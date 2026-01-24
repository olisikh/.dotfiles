{ config, lib, namespace, ... }:
let
  inherit (lib) mkIf;
in
{
  plugins.opencode = {
    enable = true;
    settings = { };
  };

  extraConfigLua = # lua
    ''
      vim.keymap.set('n', '<leader>oa', function() require('opencode').ask('@this: ', { submit = true }) end, { desc = 'opencode: ask' })
      vim.keymap.set('n', '<leader>oc', function() require('opencode').select() end, { desc = 'opencode: execute command' })
      vim.keymap.set('n', '<leader>ot', function() require('opencode').toggle() end, { desc = 'opencode: toggle' })
      vim.keymap.set({ 'x', 'n', 'v' }, 'go', function() return require('opencode').operator('@this ') end, { expr = true, desc = 'opencode: add range' })

      vim.keymap.set('n', '<S-C-u>', function() require('opencode').command('session.half.page.up') end, { desc = 'opencode: half page up' })
      vim.keymap.set('n', '<S-C-d>', function() require('opencode').command('session.half.page.down') end, { desc = 'opencode: half page down' })
        
      vim.g.opencode_opts = {
        provider = {
          enabled = "wezterm",
          wezterm = { }
        }
      }

      -- vim.api.nvim_create_autocmd("User", {
      --   pattern = "OpencodeEvent:*", -- Optionally filter event types
      --   callback = function(args)
      --     ---@type opencode.cli.client.Event
      --     local event = args.data.event
      --     ---@type number
      --     local port = args.data.port
      --
      --     -- See the available event types and their properties
      --     vim.notify(vim.inspect(event))
      --     -- Do something useful
      --     if event.type == "session.idle" then
      --       vim.notify("`opencode` finished responding")
      --     end
      --   end,
      -- })
    '';
}
