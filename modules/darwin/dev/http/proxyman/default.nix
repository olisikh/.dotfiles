{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.dev.http.proxyman;
  homebrewCfg = config.${namespace}.core.homebrew;
in
{
  options.${namespace}.dev.http.proxyman = {
    enable = mkBoolOpt false "Enable proxyman (http debugging proxy tool for macOS)";
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = homebrewCfg.enable;
      message = "proxyman requires homebrew to be enabled (core.homebrew.enable = true)";
    }];

    homebrew.casks = [ "proxyman" ];
  };
}
