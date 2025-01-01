{
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
          "harpoon2" # NOTE: plugin is not available as vimPlugin
          "copilot"
          "encoding"
          "filetype"
        ];
      };
    };
  };
}
