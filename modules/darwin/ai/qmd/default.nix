{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.ai.qmd;
in
{
  options.${namespace}.ai.qmd.enable = mkBoolOpt false "Install qmd for all system sessions";

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.${namespace}.qmd ];
  };
}
