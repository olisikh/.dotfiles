{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.network.proxyman;
  homebrewCfg = config.${namespace}.core.homebrew;
in
{
  options.${namespace}.network.proxyman = {
    enable = mkBoolOpt false "Enable proxyman";
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = homebrewCfg.enable;
      message = "proxyman requires homebrew to be enabled (core.homebrew.enable = true)";
    }];

    homebrew.casks = [ "proxyman" ];
  };
}
