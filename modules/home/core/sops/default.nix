{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.core.sops;
  home = config.home.homeDirectory;

  normalizedSecrets = lib.mapAttrs
    (
      _secretName: secret:
        secret
        // (lib.optionalAttrs (!(secret ? path) && (secret ? name)) {
          path = "${home}/.config/sops-nix/secrets/${secret.name}";
        })
    )
    cfg.secrets;
in
{
  options.${namespace}.core.sops = with lib.types; {
    enable = mkBoolOpt false "Enable sops program";
    keyFile = mkOpt str "${home}/.config/sops/age/keys.txt" "Path to the sops age keys file";
    secretsFile = mkOpt str "${home}/.config/sops/secrets.yaml" "Path to the sops secrets file";
    generateKey = mkBoolOpt true "Generate a new sops age key";
    sshKeyPaths = mkOpt (listOf str) [ "${home}/.ssh/id_ed25519" ] "List of ssh key paths to convert to age keys";
    secrets = mkOpt (attrsOf attrs) { } "Per-system sops-nix secrets to materialize (keys become filenames under ~/.config/sops-nix/secrets)";
  };

  config = mkIf cfg.enable {
    sops = {
      validateSopsFiles = false;
      defaultSopsFile = cfg.secretsFile;

      age = {
        # NOTE: These 2 properties would generate a keys.txt file if it is not present:
        # essentially doing something like this:
        # $ nix-shell -p ssh-to-age --run "ssh-to-age -private-key -i ~/.ssh/id_ed25519 > ~/.config/sops/age/keys.txt"
        # $ nix-shell -p sops --run "sops ~/.config/sops/secrets.yaml"
        inherit (cfg) sshKeyPaths generateKey keyFile;
      };

      secrets = normalizedSecrets;
    };

    home.sessionVariables = {
      SOPS_AGE_KEY_FILE = cfg.keyFile;
    };
  };
}
