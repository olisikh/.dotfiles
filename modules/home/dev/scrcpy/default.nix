{ lib, config, namespace, pkgs, ... }:
with lib;
let
  inherit (lib.${namespace}) mkOpt mkBoolOpt;

  cfg = config.${namespace}.dev.shell.scrcpy;
in
{
  options.${namespace}.dev.shell.scrcpy = with types; {
    enable = mkBoolOpt false "Enable dev.scrcpy module";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ scrcpy ];
  };
}
