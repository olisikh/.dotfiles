{ pkgs, ... }:
{
  extraPlugins = [ pkgs.vimPlugins.simple-zoom ];

  extraConfigLua = ''
    local zoom = require('simple-zoom')
    zoom.setup()

    vim.keymap.set('n', '<C-z>', zoom.toggle_zoom, {
      silent = true,
      desc = 'window: toggle maximize',
    })
  '';
}
