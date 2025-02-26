{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.wezterm;
in
{
  options.${namespace}.wezterm = {
    enable = mkBoolOpt false "Enable wezterm program";
  };

  config = mkIf cfg.enable {
    home.file = {
      ".config/wezterm".source = ./config;
    };

    programs.wezterm = {
      enable = true;
    };
  };
}
