{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.dev.shell.fd;
in
{
  options.${namespace}.dev.shell.fd = {
    enable = mkBoolOpt false "Enable fd (fast, user-friendly alternative to find)";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.fd ];
  };
}
