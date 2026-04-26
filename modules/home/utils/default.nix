{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.utils;
in
{
  options.${namespace}.utils = {
    enable = mkBoolOpt false "Enable utility tools (htop, stress, xdg-utils, watch, mkalias)";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      htop
      stress
      xdg-utils
      watch
      mkalias
      fastfetch
      hyfetch
    ];
  };
}
