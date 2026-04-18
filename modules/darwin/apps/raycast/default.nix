{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.apps.raycast;
  homebrewCfg = config.${namespace}.core.homebrew;
in
{
  options.${namespace}.apps.raycast = {
    enable = mkBoolOpt false "Enable raycast (launcher)";
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = homebrewCfg.enable;
      message = "Raycast requires homebrew to be enabled (core.homebrew.enable = true)";
    }];

    homebrew.casks = [ "raycast" ];
  };
}
