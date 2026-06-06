
{ lib, config, namespace, pkgs, ... }:
with lib;
let
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.dev.virtualization.qemu;
in
{
  options.${namespace}.dev.virtualization.qemu = {
    enable = mkBoolOpt false "Enable qemu module";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      qemu
    ];
  };
}
