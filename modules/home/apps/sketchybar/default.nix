{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.apps.sketchybar;

  sketchybarAppFont = pkgs.sketchybar-app-font;
  codexBarProviderIconsFonts = pkgs.${namespace}.codexbar-provider-icons-fonts;
in
{
  options.${namespace}.apps.sketchybar = {
    enable = mkBoolOpt false "Enable sketchybar program";
  };

  config = mkIf cfg.enable {
    home.file = {
      ".config/sketchybar/items".source = ./config/items;
      ".config/sketchybar/plugins".source = ./config/plugins;
      ".config/sketchybar/sketchybarrc".source = ./config/sketchybarrc;
      ".config/sketchybar/variables.sh".source = ./config/variables.sh;
      ".config/sketchybar/helpers/codexbar_icon_map.sh".source = "${codexBarProviderIconsFonts}/bin/icon_map.sh";
      ".config/sketchybar/helpers/icon_map.sh".source = "${sketchybarAppFont}/bin/icon_map.sh";
    };
  };
}
