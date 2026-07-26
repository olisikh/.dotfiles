{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.security.pinentry-mac;
  homebrewCfg = config.${namespace}.core.homebrew;
in
{
  options.${namespace}.security.pinentry-mac = {
    enable = mkBoolOpt false "Enable pinentry-mac (GPG pinentry dialog for macOS)";
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = homebrewCfg.enable;
      message = "pinentry-mac requires homebrew to be enabled (core.homebrew.enable = true)";
    }];

    homebrew.brews = [ "pinentry-mac" ];
  };
}