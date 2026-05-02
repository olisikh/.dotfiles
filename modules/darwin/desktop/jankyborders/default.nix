{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.desktop.jankyborders;
in
{
  options.${namespace}.desktop.jankyborders = {
    enable = mkBoolOpt false "Enable jankyborders module";
  };

  config = mkIf cfg.enable {
    services.jankyborders = {
      enable = true;
      active_color = "0xfff7768e"; # red: 0xfff7768e, white: 0xffe1e3e4
      inactive_color = "0xff494d64";
      width = 10.0;
    };
  };
}
