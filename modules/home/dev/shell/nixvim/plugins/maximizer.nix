{ ... }:
{
  plugins.mini = {
    enable = true;
    modules.misc = { };
  };

  extraConfigLua = ''
    vim.keymap.set('n', '<C-z>', MiniMisc.zoom, {
      silent = true,
      desc = 'window: toggle maximize',
    })
  '';
}
