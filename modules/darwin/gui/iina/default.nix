{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.gui.iina;
  homebrewCfg = config.${namespace}.core.homebrew;
in
{
  options.${namespace}.gui.iina = {
    enable = mkBoolOpt false "Enable iina (media player)";
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = homebrewCfg.enable;
      message = "iina requires homebrew to be enabled (core.homebrew.enable = true)";
    }];

    homebrew.casks = [ "iina" ];
  };
}
