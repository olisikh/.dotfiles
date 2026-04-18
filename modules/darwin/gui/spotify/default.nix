{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.gui.spotify;
  homebrewCfg = config.${namespace}.core.homebrew;
in
{
  options.${namespace}.gui.spotify = {
    enable = mkBoolOpt false "Enable spotify";
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = homebrewCfg.enable;
      message = "spotify requires darwin homebrew to be enabled (core.homebrew.enable = true)";
    }];

    homebrew.casks = [ "spotify" ];
  };
}
