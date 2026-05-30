{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.apps.bitwarden;
  homebrewCfg = config.${namespace}.core.homebrew;
in
{
  options.${namespace}.apps.bitwarden = {
    enable = mkBoolOpt false "Enable Bitwarden (password manager)";
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = homebrewCfg.enable;
      message = "Bitwarden requires homebrew to be enabled (core.homebrew.enable = true)";
    }];

    homebrew.casks = [ "bitwarden" ];
  };
}
