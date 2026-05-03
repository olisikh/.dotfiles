{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.dev.shell.ghui;
in
{
  options.${namespace}.dev.shell.ghui = {
    enable = mkBoolOpt false "Enable ghui (GitHub pull request TUI)";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.${namespace}.ghui ];
  };
}
