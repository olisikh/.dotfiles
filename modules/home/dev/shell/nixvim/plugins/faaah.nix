{ pkgs, nsLib, ... }:
let
  inherit (nsLib.nixvim) mkKeymaps;
in
{
  extraPlugins = [ pkgs.vimPlugins.faaah ];

  extraConfigLua = ''
    require("faaah").setup({
      defaults = {
        sound = "ahh.mp3",
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
          enabled = false,
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
