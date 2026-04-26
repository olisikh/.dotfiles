{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.apps.telegram;
  homebrewCfg = config.${namespace}.core.homebrew;
in
{
  options.${namespace}.apps.telegram = {
    enable = mkBoolOpt false "Enable Telegram";
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = homebrewCfg.enable;
      message = "Telegram requires homebrew to be enabled (core.homebrew.enable = true)";
    }];

    homebrew.casks = [ "telegram" ];
  };
}
