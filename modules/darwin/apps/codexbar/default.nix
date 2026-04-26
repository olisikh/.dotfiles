{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.apps.codexbar;
  homebrewCfg = config.${namespace}.core.homebrew;
in
{
  options.${namespace}.apps.codexbar = {
    enable = mkBoolOpt false "Enable codexbar (Menu bar plugin for tracking LLMs usage and costs)";
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = homebrewCfg.enable;
      message = "Codexbar requires homebrew to be enabled (core.homebrew.enable = true)";
    }];

    homebrew.casks = [ "codexbar" ];
  };
}
