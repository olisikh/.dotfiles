{ theme, themeStyle, ... }: { pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      wezterm
    ];
  };


  programs.wezterm = {
    enable = true;

    # TODO: Make theme configurable, derive from theme and themeStyle
    extraConfig =
      # lua
      ''
        return {
          color_scheme = "Catppuccin Mocha", -- or Macchiato, Frappe, Latte
        }
      '';
  };
}
