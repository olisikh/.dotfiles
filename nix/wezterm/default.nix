{ ... }:
{
  home.file = {
    ".config/wezterm".source = ~/.dotfiles/wezterm;
  };

  programs.wezterm = {
    enable = true;
  };
}
