{ ... }:
{
  plugins.treesj = {
    enable = true;
    settings = {
      use_default_keymaps = false;
    };
  };

  keymaps = [
    {
      key = "<leader>j";
      action = ":lua require('treesj').toggle()<cr>";
      mode = "n";
      options = { desc = "treesj: toggle"; };
    }
    {
      key = "<leader>J";
      action = ":lua require('treesj').toggle({ split = { recursive = true } })<cr>";
      mode = "n";
      options = {
        desc = "treesj: toggle (recursive)";
      };
    }
  ];
}
