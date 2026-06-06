{ lib, config, namespace, pkgs, ... }:
with lib;
let
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.media.blackhole;
in
{
  options.${namespace}.media.blackhole = {
    enable = mkBoolOpt false "Enable blackhole module (routing audio app to app)";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ blackhole ];
  };
}
