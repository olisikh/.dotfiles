{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.media.transmission;
  homebrewCfg = config.${namespace}.core.homebrew;
in
{
  options.${namespace}.media.transmission = {
    enable = mkBoolOpt false "Enable transmission (torrent client)";
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = homebrewCfg.enable;
      message = "transmission requires darwin homebrew to be enabled (core.homebrew.enable = true)";
    }];

    homebrew.casks = [ "transmission" ];
  };
}
