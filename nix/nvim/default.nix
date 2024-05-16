{ pkgs, ... }:
{
  home.file = {
    ".config/nvim".source = ~/.dotfiles/nvim;
  };

  programs.neovim = {
    enable = true;
    viAlias = false;
    vimAlias = true;
  };
}
