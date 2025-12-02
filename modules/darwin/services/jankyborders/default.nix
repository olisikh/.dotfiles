{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.services.jankyborders;
in
{
  options.${namespace}.services.jankyborders = {
    enable = mkBoolOpt false "Enable jankyborders module";
  };

  config = mkIf cfg.enable {
    # https://mynixos.com/nix-darwin/options/services.jankyborders
    services.jankyborders = {
      enable = true;
      active_color = "0xffe1e3e4";
      inactive_color = "0xff494d64";
      width = 10.0;
    };
  };
}
