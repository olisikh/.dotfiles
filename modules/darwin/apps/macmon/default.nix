{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.apps.macmon;
in
{
  options.${namespace}.apps.macmon = {
    enable = mkBoolOpt false "Enable macmon (Apple Silicon monitor CLI)";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.${namespace}.macmon ];
  };
}
