{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.fonts.sf-mono;
  homebrewCfg = config.${namespace}.core.homebrew;
in
{
  options.${namespace}.fonts.sf-mono = {
    enable = mkBoolOpt false "Enable SF Mono font via Homebrew";
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = homebrewCfg.enable;
      message = "SF Mono font requires homebrew to be enabled (core.homebrew.enable = true)";
    }];

    homebrew.casks = [ "font-sf-mono" ];
  };
}
