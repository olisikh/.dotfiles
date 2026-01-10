{ config, namespace, ... }:
let
  cfg = config.${namespace}.nixvim.plugins.opencode;
in
{
  opencode = {
    enable = cfg.enable;

    settings = { };
  };
}
