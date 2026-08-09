{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.media.calibre;
  homebrewCfg = config.${namespace}.core.homebrew;
in
{
  options.${namespace}.media.calibre = {
    enable = mkBoolOpt false "Enable Calibre (e-book manager)";
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = homebrewCfg.enable;
      message = "calibre requires darwin homebrew to be enabled (core.homebrew.enable = true)";
    }];

    homebrew.casks = [ "calibre" ];
  };
}
