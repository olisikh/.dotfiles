{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.dev.shell.yq;
in
{
  options.${namespace}.dev.shell.yq = {
    enable = mkBoolOpt false "Enable yq (command-line YAML processor, like jq for YAML)";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.yq ];
  };
}
