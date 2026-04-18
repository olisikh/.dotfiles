{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.network.clearvpn;
  homebrewCfg = config.${namespace}.core.homebrew;
in
{
  options.${namespace}.network.clearvpn = {
    enable = mkBoolOpt false "Enable clearvpn (VPN client)";
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = homebrewCfg.enable;
      message = "clearvpn requires homebrew to be enabled (core.homebrew.enable = true)";
    }];

    homebrew.casks = [ "clearvpn" ];
  };
}
