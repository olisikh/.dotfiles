{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.ai.antigravity;
in
{
  options.${namespace}.ai.antigravity = {
    enable = mkBoolOpt false "Enable antigravity (AI code editor)";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.antigravity ];
  };
}
