{ ... }: {
  plugins = {
    zen-mode = {
      enable = true;
      settings = {
        plugins = {
          gitsigns.enabled = false;
          tmux.enabled = false;
          wezterm = {
            enabled = true;
            font = "+4";
          };
        };
      };
    };
  };

  extraConfigLua = # lua 
    ''
      vim.keymap.set("n", "<leader>zz", function() require("zen-mode").toggle() end)
    '';
}
