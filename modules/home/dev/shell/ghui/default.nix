{ lib, config, namespace, pkgs, ... }:
with lib;
let
  inherit (lib.${namespace}) mkOpt mkBoolOpt;

  cfg = config.${namespace}.dev.shell.ghui;
in
{
  options.${namespace}.dev.shell.ghui = with types; {
    enable = mkBoolOpt false "Enable ghui module";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      ghui
    ];
  };
}
