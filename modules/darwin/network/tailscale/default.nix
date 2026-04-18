{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.network.tailscale;
in
{
  options.${namespace}.network.tailscale = {
    enable = mkBoolOpt false "Enable tailscale module";
  };

  config = mkIf cfg.enable {
    services.tailscale.enable = true;
  };
}
