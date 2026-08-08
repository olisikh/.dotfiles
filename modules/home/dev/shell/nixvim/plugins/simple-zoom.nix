{ pkgs, ... }:
{
  extraPlugins = [
    (pkgs.vimUtils.buildVimPlugin {
      name = "simple-zoom.nvim";
      src = pkgs.fetchFromGitHub {
        owner = "fasterius";
        repo = "simple-zoom.nvim";
        rev = "318aef7c894aab4bc90dfbe82fee01b130540afd";
        hash = "sha256-rGtWGkIjfkZZF93Ve1VVhq/stZ8TQZ3hE2E9RCW4D8c=";
      };
    })
  ];

  extraConfigLua = ''
    require('simple-zoom').setup({ hide_tabline = false })

    vim.keymap.set('n', '<C-z>', '<cmd>SimpleZoomToggle<cr>', {
      silent = true,
      desc = 'window: toggle maximize',
    })
  '';
}
