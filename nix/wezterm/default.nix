{ theme, themeStyle, ... }: { pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      wezterm
    ];
  };


  programs.wezterm = {
    enable = true;
    extraConfig =
      # lua
      ''
        return {
          -- TODO: Capitalize the first letter of the theme and themeStyle instead 
          color_scheme = "Catppuccin Mocha", -- or Macchiato, Frappe, Latte
          keys = {
            -- Make Option-Left equivalent to Alt-b which many line editors interpret as backward-word
            {key="LeftArrow", mods="OPT", action=wezterm.action{SendString="\x1bb"}},
            -- Make Option-Right equivalent to Alt-f; forward-word
            {key="RightArrow", mods="OPT", action=wezterm.action{SendString="\x1bf"}},
          }
        }
      '';
  };
}
