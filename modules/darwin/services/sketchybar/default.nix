{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.services.sketchybar;
  userCfg = config.${namespace}.user;
in
{
  options.${namespace}.services.sketchybar = {
    enable = mkBoolOpt false "Enable sketchybar module";
  };

  config = mkIf cfg.enable {
    services.sketchybar = {
      enable = true;
      extraPackages = with pkgs; [
        sops
        age
        jq
        sketchybar-app-font
      ];
    };

    environment = {
      variables = {
        HOME = userCfg.home;
        SOPS_AGE_KEY_FILE = "${userCfg.home}/.config/sops/age/keys.txt";
      };
    };

    snowfallorg.users.${userCfg.username}.home.config = {
      xdg.configFile = {
        "sketchybar".source = ./config;
      };
    };
  };
}
