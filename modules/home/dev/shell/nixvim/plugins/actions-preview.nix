{ namespaceLib, ... }:
{
  plugins.actions-preview = {
    enable = true;

    settings = { };
  };

  keymaps = namespaceLib.nixvimKeymaps [
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
