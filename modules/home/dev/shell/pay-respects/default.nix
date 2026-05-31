{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.dev.shell.pay-respects;
in
{
  options.${namespace}.dev.shell.pay-respects = {
    enable = lib.${namespace}.mkBoolOpt false "Enable pay-respects (command correction tool, thefuck alternative)";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.pay-respects ];

    programs.zsh.initContent = lib.${namespace}.mkZshLate
      # zsh
      ''
        eval "$(pay-respects zsh)"
      '';
  };
}
