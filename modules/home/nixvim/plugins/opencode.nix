{ config, lib, namespace, ... }:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.nixvim.plugins.opencode;
  opencodeCfg = config.${namespace}.opencode;
in
{
  opencode = mkIf opencodeCfg.enable {
    enable = cfg.enable;

    settings = { };
  };
}
