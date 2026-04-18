{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.ai.claude-code;
  homebrewCfg = config.${namespace}.core.homebrew;
in
{
  options.${namespace}.ai.claude-code = {
    enable = mkBoolOpt false "Enable claude-code (Anthropic CLI)";
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = homebrewCfg.enable;
      message = "claude-code requires homebrew to be enabled (core.homebrew.enable = true)";
    }];

    homebrew.casks = [ "claude-code" ];
  };
}
