{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.apps.xcodesapp;
  homebrewCfg = config.${namespace}.core.homebrew;
in
{
  options.${namespace}.apps.xcodesapp = {
    enable = mkBoolOpt false "Enable xcodes (Xcode version manager)";
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = homebrewCfg.enable;
      message = "xcodes requires homebrew to be enabled (core.homebrew.enable = true)";
    }];

    homebrew.casks = [ "xcodes-app" ];
  };
}
