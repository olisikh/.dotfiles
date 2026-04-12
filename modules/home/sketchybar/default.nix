{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.sketchybar;
in
{
  options.${namespace}.sketchybar = {
    enable = mkBoolOpt false "Enable sketchybar program";
  };

  config = mkIf cfg.enable {
    home.file = {
      ".config/sketchybar/items".source = ./config/items;
      ".config/sketchybar/plugins".source = ./config/plugins;
      ".config/sketchybar/sketchybarrc".source = ./config/sketchybarrc;
      ".config/sketchybar/variables.sh".source = ./config/variables.sh;
      ".config/sketchybar/helpers/icon_map.sh".source = "${pkgs.sketchybar-app-font}/bin/icon_map.sh";
    };
  };
}
