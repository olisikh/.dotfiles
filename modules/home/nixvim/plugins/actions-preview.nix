{ ... }:
{
  plugins.actions-preview = {
    enable = true;

    settings = { };
  };

  keymaps = [
    {
      mode = [ "n" "v" ];
      key = "gra";
      action = ":lua require('actions-preview').code_actions()<CR>";
      options = {
        desc = "lsp: code [a]ction";
        silent = true;
        noremap = true;
      };
    }
  ];
}
