{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  inherit (lib.${namespace}.zsh) mkLate;

  cfg = config.${namespace}.apps.wezterm;
in
{
  options.${namespace}.apps.wezterm = {
    enable = mkBoolOpt false "Enable wezterm program";
  };

  config = mkIf cfg.enable {
    home.file = {
      ".config/wezterm".source = ./config;
    };

    programs.wezterm = {
      enable = true;
    };

    programs.zsh.initContent = mkLate
      # zsh
      ''
        # play faaah sound
        alias faaah="echo -e '\a'"
      '';
  };
}
