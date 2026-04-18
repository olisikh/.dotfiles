{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.ai.codex;
  homebrewCfg = config.${namespace}.core.homebrew;
in
{
  options.${namespace}.ai.codex = {
    enable = mkBoolOpt false "Enable codex (OpenAI CLI)";
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = homebrewCfg.enable;
      message = "codex requires homebrew to be enabled (core.homebrew.enable = true)";
    }];

    homebrew.casks = [ "codex" ];
  };
}
