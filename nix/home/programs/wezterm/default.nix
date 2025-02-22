{ ... }:
{
  home.file = {
    ".config/wezterm".source = ./config;
  };

  programs.wezterm = {
    enable = true;
  };
}
