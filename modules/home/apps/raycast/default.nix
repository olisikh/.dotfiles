{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.apps.raycast;
in
{
  options.${namespace}.apps.raycast = {
    enable = mkBoolOpt false "Enable raycast launcher";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.raycast ];
  };
}
