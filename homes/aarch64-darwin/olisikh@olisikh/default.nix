{ pkgs, ... }:
let
  jdk = pkgs.jdk17;
  scala = pkgs.scala-next;
in
{
  olisikh = {
    direnv.enable = true;
    zsh.enable = true;
    fzf.enable = true;
    zoxide.enable = true;
    wezterm.enable = true;
    ripgrep.enable = true;
    starship.enable = true;
    git = {
      enable = true;
      userName = builtins.getEnv "GIT_NAME";
      userEmail = builtins.getEnv "GIT_EMAIL";
      signingKey = builtins.getEnv "GIT_SIGNING_KEY";
    };
    mc.enable = true;
    nixvim.enable = true;
    sketchybar.enable = true;

    shared.enable = true;
  };
}
