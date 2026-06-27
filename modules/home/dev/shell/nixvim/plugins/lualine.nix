{ lib, ... }:
{
  plugins = {
    lualine = {
      enable = true;
      settings = {
        options = {
          theme = "catppuccin-nvim";
          globalstatus = true; # show global statusline instead of showing it in each window
        };
        sections = {
          lualine_c = [
            "filename"
          ];
          lualine_x = [
            "harpoon2"
            {
              __unkeyed-1 = lib.nixvim.mkRaw ''
                function()
                  local opencode_status = require("opencode").statusline()
                  return opencode_status:gsub("localhost", "")
                end
              '';
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
