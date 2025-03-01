{ lib, config, namespace, inputs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.sops;
  home = config.${namespace}.user.home;
in
{
  options.${namespace}.sops = {
    enable = mkBoolOpt false "Enable sops program";
  };

  config = mkIf cfg.enable {
    sops = {
      validateSopsFiles = false;
      defaultSopsFile = "${home}/.config/sops/secrets.yaml";

      age = {
        keyFile = "${home}/.config/sops/age/keys.txt";
        sshKeyPaths = [ "${home}/.ssh/id_ed25519" ];
        generateKey = true;
      };

      secrets = {
        userEmail = { };
        signingKey = { };
      };
    };
  };
}
