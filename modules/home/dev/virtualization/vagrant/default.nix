{ lib, config, namespace, pkgs, ... }:
with lib;
let
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.dev.virtualization.vagrant;
in
{
  options.${namespace}.dev.virtualization.vagrant = {
    enable = mkBoolOpt false "Enable vagrant module";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      vagrant
    ];
  };
}
