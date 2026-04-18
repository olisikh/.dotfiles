{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.dev.shell.starship;
in
{
  options.${namespace}.dev.shell.starship = {
    enable = mkBoolOpt false "Enable starship (fast, customizable cross-shell prompt)";
  };

  config = mkIf cfg.enable {
    programs.starship = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
