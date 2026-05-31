{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.dev.shell.zoxide;
in
{
  options.${namespace}.dev.shell.zoxide = {
    enable = lib.${namespace}.mkBoolOpt false "Enable zoxide (smarter cd command with learning)";
  };

  config = mkIf cfg.enable {
    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    programs.zsh.initContent = lib.${namespace}.mkZshLate
      # zsh
      ''
        alias zz="z -"
      '';
  };
}
