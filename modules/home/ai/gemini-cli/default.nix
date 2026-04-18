{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.ai.gemini;
in
{
  options.${namespace}.ai.gemini = {
    enable = mkBoolOpt false "Enable gemini (AI harness)";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.gemini-cli ];
  };
}
