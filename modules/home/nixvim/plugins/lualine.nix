{ ... }: {
  lualine = {
    enable = true;
    settings = {
      options = {
        theme = "catppuccin";
        globalstatus = true; # show global statusline instead of showing it in each window
      };
      sections = {
        lualine_c = [
          "filename"
        ];
        lualine_x = [
          "harpoon2"
          "copilot"
          "avante"
          "encoding"
          "filetype"
        ];
      };
    };
  };
}
