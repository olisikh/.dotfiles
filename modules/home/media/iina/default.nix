{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.media.iina;
in
{
  options.${namespace}.media.iina = {
    enable = mkBoolOpt false "Enable iina (media player for macOS)";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.iina ];
  };
}
