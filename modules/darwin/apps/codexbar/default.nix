{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.apps.codexbar;
  homebrewCfg = config.${namespace}.core.homebrew;
in
{
  options.${namespace}.apps.codexbar = {
    enable = mkBoolOpt false "Enable codexbar (OpenAI Codex in menu bar)";
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = homebrewCfg.enable;
      message = "Codexbar requires homebrew to be enabled (core.homebrew.enable = true)";
    }];

    homebrew.casks = [ "codexbar" ];
  };
}
