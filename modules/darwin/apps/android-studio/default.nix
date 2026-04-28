{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.apps.android-studio;
  homebrewCfg = config.${namespace}.core.homebrew;
in
{
  options.${namespace}.apps.android-studio = {
    enable = mkBoolOpt false "Enable Android Studio";
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = homebrewCfg.enable;
      message = "Android Studio requires homebrew to be enabled (core.homebrew.enable = true)";
    }];

    homebrew.casks = [ "android-studio" ];
  };
}
