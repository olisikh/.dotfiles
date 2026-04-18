{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.dev.shell.jq;
in
{
  options.${namespace}.dev.shell.jq = {
    enable = mkBoolOpt false "Enable jq (command-line JSON processor)";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.jq ];
  };
}
