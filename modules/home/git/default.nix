{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt enabled;

  cfg = config.${namespace}.git;
  user = config.${namespace}.user;
  secrets = config.sops.secrets;
in
{
  options.${namespace}.git = with types; {
    enable = mkBoolOpt false "Enable git program";
    signByDefault = mkOpt bool false "Whether to sign commits by default.";
  };

  config = mkIf cfg.enable {
    programs.git = enabled;

    home.activation.writeGitConfig = lib.mkAfter ''
      cat > ~/.gitconfig <<EOF
      [user]
          name = ${user.fullName}
          email = $(cat ${secrets.userEmail.path})
          ${if (secrets.signingKey.path != "") then "signingkey = $(cat ${secrets.signingKey.path})" else ""}
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
