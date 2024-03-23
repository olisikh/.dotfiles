{ pkgs, ... }:
let
  userName = builtins.getEnv "GIT_NAME";
  userEmail = builtins.getEnv "GIT_EMAIL";
in
{
  programs.git = {
    enable = true;
    userName = userName;
    userEmail = userEmail;

    extraConfig = {
      core = {
        autocrlf = "input";
        excludesfile = "~/.gitignore_global";
      };

      submodule = {
        recurse = true;
      };

      init = {
        defaultBranch = "main";
      };
    };
  };
}
