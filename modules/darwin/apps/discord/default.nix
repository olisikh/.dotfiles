{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.apps.discord;
  homebrewCfg = config.${namespace}.core.homebrew;
in
{
  options.${namespace}.apps.discord = {
    enable = mkBoolOpt false "Enable Discord";
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = homebrewCfg.enable;
      message = "Discord requires homebrew to be enabled (core.homebrew.enable = true)";
    }];

    homebrew.casks = [ "discord" ];
  };
}
