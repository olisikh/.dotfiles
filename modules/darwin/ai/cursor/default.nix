{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.ai.cursor;
  homebrewCfg = config.${namespace}.core.homebrew;
in
{
  options.${namespace}.ai.cursor = {
    enable = mkBoolOpt false "Enable cursor (Cursor CLI)";
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = homebrewCfg.enable;
      message = "cursor requires homebrew to be enabled (core.homebrew.enable = true)";
    }];

    homebrew.casks = [ "cursor-cli" ];
  };
}
