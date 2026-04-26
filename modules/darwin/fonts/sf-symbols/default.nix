{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.fonts.sf-symbols;
  homebrewCfg = config.${namespace}.core.homebrew;
in
{
  options.${namespace}.fonts.sf-symbols = {
    enable = mkBoolOpt false "Enable SF Symbols (Apple's icon font library)";
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = homebrewCfg.enable;
      message = "SF Symbols requires homebrew to be enabled (core.homebrew.enable = true)";
    }];

    homebrew.casks = [ "sf-symbols" ];
  };
}
