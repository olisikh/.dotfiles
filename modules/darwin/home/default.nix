{ lib, config, namespace, ... }:
with lib;
let
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.home;
in
{
  options.${namespace}.home = {
    enable = mkBoolOpt true "Enable integration with home-manager";
  };

  config = mkIf cfg.enable {
    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;
    };
  };
}
