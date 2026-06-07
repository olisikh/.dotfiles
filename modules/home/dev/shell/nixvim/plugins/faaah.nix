{ pkgs, nsLib, ... }:
let
  inherit (nsLib.nixvim) mkKeymaps;
  faaahPlugin = pkgs.fetchFromGitHub {
    owner = "olisikh";
    repo = "faaah.nvim";
    rev = "fbd8b2550e8c616228455e8a2a8f28d2d5de40d4";
    sha256 = "sha256-30dVOHA0bPiPZdJryXvMNOLH+QkMVbI1LcsYFkrnFV0=";
  };
in
{
  extraPlugins = [ faaahPlugin ];

  extraConfigLua = ''
    require("faaah").setup({
      defaults = {
        throttle_ms = 2000,
      },
      sources = {
        diagnostics = {
          enabled = true,
        },
        neotest = {
          enabled = true,
        },
        notifications = { 
          enabled = true,
        },
      },
    })
  '';

  keymaps = mkKeymaps [
    {
      key = "<leader>um";
      action = ":Faaah toggle<cr>";
      mode = "n";
      options = {
        desc = "faaah: toggle mute";
      };
    }
  ];
}
