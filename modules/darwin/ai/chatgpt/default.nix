{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.ai.chatgpt;
  homebrewCfg = config.${namespace}.core.homebrew;
in
{
  options.${namespace}.ai.chatgpt = {
    enable = mkBoolOpt false "Enable chatgpt (OpenAI desktop app)";
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = homebrewCfg.enable;
      message = "chatgpt requires homebrew to be enabled (core.homebrew.enable = true)";
    }];

    homebrew.casks = [ "chatgpt" ];
  };
}
