{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.dev.shell.just;
in
{
  options.${namespace}.dev.shell.just = {
    enable = mkBoolOpt false "Enable just (command runner)";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.just ];
  };
}
