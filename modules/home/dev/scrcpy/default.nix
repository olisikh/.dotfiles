{ lib, config, namespace, pkgs, ... }:
with lib;
let
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.dev.shell.scrcpy;
in
{
  options.${namespace}.dev.shell.scrcpy = {
    enable = mkBoolOpt false "Enable scrcpy module";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ scrcpy ];
  };
}
