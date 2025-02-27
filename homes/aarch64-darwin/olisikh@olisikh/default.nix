{ lib, namespace, ... }:
let
  inherit (lib.${namespace}) enabled;

  userName = "Oleksii Lisikh";
  userEmail = "alisiikh@gmail.com";
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
    git = {
      inherit userName userEmail;
      enable = true;
    };
    mc = enabled;
    nixvim = enabled;
    sketchybar = enabled;
    shared = enabled;
  };
}
