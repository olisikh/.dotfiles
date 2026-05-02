{ lib, config, namespace, ... }:
with lib;
let
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.desktop.handy;
  homebrewCfg = config.${namespace}.core.homebrew;
in
{
  options.${namespace}.desktop.handy = {
    enable = mkBoolOpt false "Enable handy module";
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = homebrewCfg.enable;
      message = "Handy requires homebrew to be enabled (core.homebrew.enable = true)";
    }];

    homebrew.casks = [ "handy" ];

    # symlink handy CLI tool to .local/bin
  };
}
