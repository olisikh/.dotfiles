{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.apps.obsidian;
  homebrewCfg = config.${namespace}.core.homebrew;
in
{
  options.${namespace}.apps.obsidian = {
    enable = mkBoolOpt false "Enable Obsidian";
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = homebrewCfg.enable;
      message = "Obsidian requires homebrew to be enabled (core.homebrew.enable = true)";
    }];

    homebrew.casks = [ "obsidian" ];
  };
}
