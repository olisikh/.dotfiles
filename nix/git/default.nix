{ lib, ... }:
let
  # TODO: pass all these as arguments to the module instead of env vars
  userName = builtins.getEnv "GIT_NAME";
  userEmail = builtins.getEnv "GIT_EMAIL";
  signingKey = builtins.getEnv "GIT_SIGNING_KEY";
in
{
  programs.git = {
    enable = true;
    userName = userName;
    userEmail = userEmail;

    signing = lib.mkIf (signingKey != "") {
      key = signingKey;
      signByDefault = true;
    };

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
