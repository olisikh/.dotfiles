{ config, namespace, ... }:
let
  cfg = config.${namespace}.nixvim.plugins.copilot;
in
{
  copilot-lua = {
    enable = cfg.enable;
    settings = {
      suggestion = {
        enabled = true;
        auto_trigger = true;
      };
    };
  };
}
