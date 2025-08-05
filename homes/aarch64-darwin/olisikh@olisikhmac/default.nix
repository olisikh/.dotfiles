{ lib, namespace, ... }:
let
  inherit (lib.${namespace}) enabled disabled;
in
{
  olisikh = {
    direnv = enabled;
    zsh = enabled;
    fzf = enabled;
    zoxide = enabled;
    bat = enabled;
    wezterm = enabled;
    ripgrep = enabled;
    starship = enabled;
    git = enabled;
    yazi = enabled;
    nixvim = {
      enable = true;
      nightly = true;
      plugins = {
        obsidian = disabled;
      };
    };
    user = enabled;
    sops = enabled;
  };
}
