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

    snowfallorg.users.${userCfg.username}.home.config = {
      xdg.configFile = {
        "sketchybar/items".source = ./config/items;
        "sketchybar/plugins".source = ./config/plugins;
        "sketchybar/sketchybarrc".source = ./config/sketchybarrc;
        "sketchybar/variables.sh".source = ./config/variables.sh;

        "sketchybar/helpers/icon_map.sh".source = "${pkgs.sketchybar-app-font}/bin/icon_map.sh";
      };
    };
  };
}
