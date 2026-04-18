{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.security.crypto;
in
{
  options.${namespace}.security.crypto = {
    enable = mkBoolOpt false "Enable crypto/security tools (age, gnupg, sops)";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      age
      gnupg
      sops
    ];
  };
}
