{ lib, config, namespace, ... }:
with lib;
let
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.dev.virtualization.virtualbox;
  homebrewCfg = config.${namespace}.core.homebrew;
in
{
  options.${namespace}.dev.virtualization.virtualbox = {
    enable = mkBoolOpt false "Enable virtualbox module";
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = homebrewCfg.enable;
      message = "virtualbox requires homebrew to be enabled (core.homebrew.enable = true)";
    }];

    homebrew.casks = [ "virtualbox" ];
  };
}
