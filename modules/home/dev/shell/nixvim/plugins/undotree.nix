{ namespaceLib, ... }:
{
  plugins = {
    undotree = {
      enable = true;
      settings = {
        autoOpenDiff = true;
        focusOnToggle = true;
      };
    };
  };

  keymaps = namespaceLib.nixvimKeymaps [
    # nmap('<leader>u', vim.cmd.UndotreeToggle, { desc = 'open undo tree' })
    {
      key = "<leader>u";
      action = ":UndotreeToggle<cr>";
      mode = "n";
      options = {
        desc = "undotree: toggle";
      };
    }
  ];
}
