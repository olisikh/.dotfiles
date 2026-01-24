{ lib, ... }:
{
  plugins = {
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
            {
              __unkeyed-1 = lib.nixvim.mkRaw ''require("opencode").statusline'';
            }
            "copilot"
            "encoding"
            "filetype"
          ];
        };
      };
    };
  };
}
