{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.ai.gemini-cli;
in
{
  options.${namespace}.ai.gemini-cli = {
    enable = mkBoolOpt false "Enable gemini-cli (AI harness)";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.gemini-cli ];
  };
}
