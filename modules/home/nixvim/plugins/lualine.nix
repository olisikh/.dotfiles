{...}:{
  lualine = {
    enable = true;
    settings = {
      options = {
        theme = "catppuccin";
      };
      sections = {
        lualine_c = [
          "filename"
        ];
        lualine_x = [
          "harpoon2"
          "copilot"
          "encoding"
          "filetype"
        ];
      };
    };
  };
}
