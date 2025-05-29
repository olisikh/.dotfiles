{ lib, namespace, ... }:
let
  inherit (lib.${namespace}) enabled;
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
    mc = enabled;
    nixvim = {
      enable = true;
      nightly = false;
    };
    user = enabled;
    sops = enabled;
  };
}
