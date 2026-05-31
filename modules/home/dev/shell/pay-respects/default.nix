{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}.zsh) mkLate;

  cfg = config.${namespace}.dev.shell.pay-respects;
in
{
  options.${namespace}.dev.shell.pay-respects = {
    enable = lib.${namespace}.mkBoolOpt false "Enable pay-respects (command correction tool, thefuck alternative)";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.pay-respects ];

    programs.zsh.initContent = mkLate
      # zsh
      ''
        eval "$(pay-respects zsh)"
      '';
  };
}
