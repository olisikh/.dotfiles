{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.apps.betterdisplay;
  homebrewCfg = config.${namespace}.core.homebrew;
in
{
  options.${namespace}.apps.betterdisplay = {
    enable = mkBoolOpt false "Enable betterdisplay (display management)";
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = homebrewCfg.enable;
      message = "BetterDisplay requires homebrew to be enabled (core.homebrew.enable = true)";
    }];

    homebrew.casks = [ "betterdisplay" ];
  };
}
