{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.dev.shell.eza;
in
{
  options.${namespace}.dev.shell.eza = {
    enable = mkBoolOpt false "Enable eza (modern replacement for ls with git support and icons)";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.eza ];
  };
}
