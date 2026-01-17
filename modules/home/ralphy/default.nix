{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.ralphy;
in
{
  options.${namespace}.ralphy = {
    enable = mkBoolOpt false "Enable ralphy AI coding loop CLI program";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs.${namespace}; [
      ralphy
    ];
  };
}
