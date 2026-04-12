{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt enabled;

  cfg = config.${namespace}.git;
  userCfg = config.${namespace}.user;

  secrets = config.sops.secrets;
  userEmailPath = lib.attrByPath [ "userEmail" "path" ] "" secrets;
  signingKeyPath = lib.attrByPath [ "signingKey" "path" ] "" secrets;
in
{
  options.${namespace}.git = with types; {
    enable = mkBoolOpt false "Enable git program";
    signByDefault = mkOpt bool false "Whether to sign commits by default.";
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = userEmailPath != "";
        message = "olisikh.git.enable requires sops secret 'userEmail' (set olisikh.sops.secrets.userEmail = { };).";
      }
    ];

    programs.git = enabled;

    home.activation.writeGitConfig = lib.mkAfter ''
      cat > ~/.gitconfig <<EOF
      [user]
          name = ${userCfg.name}
          email = $(cat ${userEmailPath})
          ${if (signingKeyPath != "") then "signingkey = $(cat ${signingKeyPath})" else ""}
      [commit]
          gpgSign = ${toString cfg.signByDefault}
      [core]
          editor = nvim
          autocrlf = "input";
          excludesfile = "~/.gitignore_global";
      [pull]
          rebase = true
      [submodule]
          recurse = true
      [init]
          defaultBranch = main
      EOF
    '';
  };
}
