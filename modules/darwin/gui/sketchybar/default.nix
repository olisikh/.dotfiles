{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.gui.sketchybar;
  userCfg = config.${namespace}.core.user;
in
{
  options.${namespace}.gui.sketchybar = {
    enable = mkBoolOpt false "Enable sketchybar module";
  };

  config = mkIf cfg.enable {
    fonts.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      sketchybar-app-font
    ];

    services.sketchybar = {
      enable = true;
      extraPackages = with pkgs; [ sops age jq ];
    };

    environment = {
      variables = {
        HOME = userCfg.home;
        SOPS_AGE_KEY_FILE = "${userCfg.home}/.config/sops/age/keys.txt";
      };
    };
  };
}
