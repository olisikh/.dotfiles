{ lib, config, namespace, ... }:
with lib;
let
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.core.home;
in
{
  options.${namespace}.core.home = {
    enable = mkBoolOpt true "Enable integration with home-manager";
  };

  config = mkIf cfg.enable {
    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;
    };
  };
}
