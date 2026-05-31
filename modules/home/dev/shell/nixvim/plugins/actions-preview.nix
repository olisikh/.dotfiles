{ nsLib, ... }:
let
  inherit (nsLib.nixvim) mkKeymaps;
in
{
  plugins.actions-preview = {
    enable = true;
    settings = { };
  };

  keymaps = mkKeymaps [
    {
      mode = [ "n" "v" ];
      key = "gra";
      action = ":lua require('actions-preview').code_actions()<CR>";
      options = {
        desc = "lsp: code [a]ction";
      };
    }
  ];
}
