{ lib, namespace, ... }:
let
  inherit (lib.${namespace}) enabled;


  userName = builtins.getEnv "GIT_NAME";
  userEmail = builtins.getEnv "GIT_EMAIL";
  signingKey = builtins.getEnv "GIT_SIGNING_KEY";
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
      inherit userName userEmail signingKey;
      enable = true;
    };
    mc = enabled;
    nixvim = enabled;
    sketchybar = enabled;
    shared = enabled;
  };
}
