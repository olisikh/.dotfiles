{ nsLib, ... }:
let
  inherit (nsLib.nixvim) mkKeymaps;
in
{
  plugins.fff = {
    enable = false;
    settings.layout = {
      prompt_position = "bottom";
      preview_position = "top";
      preview_size = 0.6;
    };
  };

  keymaps = mkKeymaps [
    {
      key = "<leader>sp";
      action = ":lua require('fff').find_files()<cr>";
      mode = "n";
      options.desc = "fff: [s]earch [p]roject files";
    }
    {
      key = "<leader>sg";
      action = ":lua require('fff').live_grep()<cr>";
      mode = "n";
      options.desc = "fff: [s]earch [g]rep";
    }
  ];
}
