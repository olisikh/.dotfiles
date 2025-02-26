{ lib, config, namespace, types, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.git;
in
{
  options.${namespace}.git = with types; {
    enable = mkBoolOpt false "Enable git program";
    userName = mkOpt str "" "The name to use for git commits";
    userEmail = mkOpt str "" "The email to use for git commits";
    signingKey = mkOpt str "" "The GPG key to use for signing commits";
  };

  programs.git = mkIf cfg.enable {
    inherit (cfg) userName userEmail;

    enable = true;

    signing = lib.mkIf (cfg.signingKey != "") {
      key = cfg.signingKey;
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
