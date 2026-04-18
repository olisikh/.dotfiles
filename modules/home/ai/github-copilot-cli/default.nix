{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.ai.github-copilot-cli;
in
{
  options.${namespace}.ai.github-copilot-cli = {
    enable = mkBoolOpt false "Enable GitHub Copilot CLI";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.github-copilot-cli ];
  };
}
