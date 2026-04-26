{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.fonts.sf-pro;
  homebrewCfg = config.${namespace}.core.homebrew;
in
{
  options.${namespace}.fonts.sf-pro = {
    enable = mkBoolOpt false "Enable SF Pro font via Homebrew";
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = homebrewCfg.enable;
      message = "SF Pro font requires homebrew to be enabled (core.homebrew.enable = true)";
    }];

    homebrew.casks = [ "font-sf-pro" ];
  };
}
