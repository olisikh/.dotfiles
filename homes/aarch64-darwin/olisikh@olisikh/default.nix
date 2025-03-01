{ lib, namespace, config, ... }:
let
  inherit (lib.${namespace}) enabled;
  secrets = config.sops.secrets;
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
    sketchybar = enabled;
    user = enabled;
    sops = enabled;
  };
}
