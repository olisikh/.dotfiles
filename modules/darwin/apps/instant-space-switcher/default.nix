{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.apps.instant-space-switcher;
  homebrewCfg = config.${namespace}.core.homebrew;
in
{
  options.${namespace}.apps.instant-space-switcher = {
    enable = mkBoolOpt false "Enable InstantSpaceSwitcher (native instant macOS space switching)";
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = homebrewCfg.enable;
      message = "InstantSpaceSwitcher requires homebrew to be enabled (core.homebrew.enable = true)";
    }];

    homebrew.casks = [{
      name = "jurplel/tap/instant-space-switcher";
      trusted = true;
    }];
  };
}
