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
    # NOTE: good example of sketchybar configuration
    # https://github.com/khaneliman/khanelinix/blob/60bc9ff5b65ca7e107de3b288e16998fd2b01c88/modules/home/programs/graphical/bars/sketchybar/default.nix
    services.sketchybar = {
      enable = true;
      extraPackages = with pkgs; [
        jq
        sketchybar-app-font
      ];
    };

    environment.systemPackages = with pkgs; with pkgs.${namespace}; [
      lua5_4
      sbarlua
    ];

    snowfallorg.users.${userCfg.username}.home.config = {
      xdg.configFile = {
        "sketchybar/sketchybarrc".source = ./config/sketchybarrc;
        "sketchybar/variables.sh".source = ./config/variables.sh;
        "sketchybar/items".source = ./config/items;
        "sketchybar/plugins".source = ./config/plugins;
      };
    };
  };
}
