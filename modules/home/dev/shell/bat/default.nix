{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.dev.shell.bat;
in
{
  options.${namespace}.dev.shell.bat = {
    enable = mkBoolOpt false "Enable bat (cat clone with syntax highlighting and git integration)";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.bat ];
  };
}
