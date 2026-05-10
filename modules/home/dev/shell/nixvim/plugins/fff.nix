{ ... }:
{

  plugins.fff = {
    enable = true;
  };

  keymaps = [
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
