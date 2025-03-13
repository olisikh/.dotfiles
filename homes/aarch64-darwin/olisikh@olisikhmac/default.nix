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
    wezterm = enabled;
    ripgrep = enabled;
    starship = enabled;
    git = enabled;
    mc = enabled;
    nixvim = enabled;
    user = enabled;
    sops = enabled;
  };
}
