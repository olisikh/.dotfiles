{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.sops;
  home = config.${namespace}.user.home;
in
{
  options.${namespace}.sops = with lib.types; {
    enable = mkBoolOpt false "Enable sops program";
    ageKeysFile = mkOpt str "${home}/.config/sops/age/keys.txt" "Path to the sops age keys file";
    secretsFile = mkOpt str "${home}/.config/sops/secrets.yaml" "Path to the sops secrets file";
  };

  config = mkIf cfg.enable {
    sops = {
      validateSopsFiles = false;
      defaultSopsFile = cfg.secretsFile;

      age = {
        keyFile = cfg.ageKeysFile;

        # NOTE: These 2 properties would generate a keys.txt file if it is not present:
        # essentially doing sometihng like this:
        # $ nix-shell -p ssh-to-age --run "ssh-to-age -private-key -i ~/.ssh/id_ed25519 > ~/.config/sops/age/keys.txt"
        sshKeyPaths = [ "${home}/.ssh/id_ed25519" ];
        generateKey = true;
      };

      secrets = {
        userEmail = { };
        signingKey = { };
      };
    };

    home.sessionVariables = {
      SOPS_AGE_KEY_FILE = /Users/olisikh/.config/sops/age/keys.txt;
    };
  };
}
