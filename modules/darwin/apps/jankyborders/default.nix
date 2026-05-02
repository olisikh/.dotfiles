{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.apps.jankyborders;
in
{
  options.${namespace}.apps.jankyborders = {
    enable = mkBoolOpt false "Enable jankyborders module";
  };

  config = mkIf cfg.enable {
    services.jankyborders = {
      enable = true;
      active_color = "0xff7aa2f7"; # red: 0xfff7768e, white: 0xffe1e3e4, blue: 0xff7aa2f7
      inactive_color = "0xff494d64";
      width = 10.0;
    };
  };
}
