{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.ai.pi;
in
{
  options.${namespace}.ai.pi = {
    enable = mkBoolOpt false "Enable pi terminal coding agent";
  };

  config = mkIf cfg.enable {
    programs.pi.coding-agent = {
      enable = true;
    };
  };
}
