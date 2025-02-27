{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf types;
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

  config = mkIf cfg.enable {
    programs.git = {
      enable = true;
      inherit (cfg) userName userEmail;

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
  };
}
