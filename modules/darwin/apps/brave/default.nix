{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.apps.brave;
  homebrewCfg = config.${namespace}.core.homebrew;
in
{
  options.${namespace}.apps.brave = {
    enable = mkBoolOpt false "Enable Brave browser";
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = homebrewCfg.enable;
      message = "Brave requires homebrew to be enabled (core.homebrew.enable = true)";
    }];

    homebrew.casks = [ "brave-browser" ];
  };
}
