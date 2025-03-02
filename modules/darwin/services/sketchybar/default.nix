{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.services.sketchybar;
  user = config.${namespace}.user;
in
{
  options.${namespace}.services.sketchybar = {
    enable = mkBoolOpt false "Enable sketchybar module";
  };

  config = mkIf cfg.enable {
    services = {
      # NOTE: good example of sketchybar configuration
      # https://github.com/khaneliman/khanelinix/blob/60bc9ff5b65ca7e107de3b288e16998fd2b01c88/modules/home/programs/graphical/bars/sketchybar/default.nix

      sketchybar = {
        enable = true;
        extraPackages = with pkgs; [
          jq
          sketchybar-app-font
        ];
      };
    };

    environment.systemPackages = with pkgs; with pkgs.${namespace}; [
      lua5_4
      sbarlua
    ];

    snowfallorg.users.${user.name}.home.config = {
      home.file = {
        ".config/sketchybar".source = ./config;
      };
    };
  };
}
