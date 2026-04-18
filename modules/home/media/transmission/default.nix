{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.media.transmission;
in
{
  options.${namespace}.media.transmission = {
    enable = mkBoolOpt false "Enable transmission (torrent client)";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.transmission_4 ];
  };
}
