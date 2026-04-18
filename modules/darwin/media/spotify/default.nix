{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.media.spotify;
  homebrewCfg = config.${namespace}.core.homebrew;
in
{
  options.${namespace}.media.spotify = {
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
