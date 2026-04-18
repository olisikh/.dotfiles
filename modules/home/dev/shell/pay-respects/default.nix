{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.dev.shell.pay-respects;
in
{
  options.${namespace}.dev.shell.pay-respects = {
    enable = mkBoolOpt false "Enable pay-respects (command correction tool, thefuck alternative)";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.pay-respects ];
  };
}
