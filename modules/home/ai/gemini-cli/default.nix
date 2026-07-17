{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.ai.gemini;
in
{
  options.${namespace}.ai.gemini = {
    enable = mkBoolOpt false "Enable Gemini CLI";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.gemini-cli ];
  };
}
