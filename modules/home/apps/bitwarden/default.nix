{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.apps.bitwarden;
in
{
  options.${namespace}.apps.bitwarden = {
    enable = mkBoolOpt false "Enable bitwarden-desktop (password manager)";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.bitwarden-desktop ];
  };
}
