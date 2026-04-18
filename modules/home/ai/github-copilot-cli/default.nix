{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.ai.gh-copilot;
in
{
  options.${namespace}.ai.gh-copilot = {
    enable = mkBoolOpt false "Enable GitHub Copilot CLI";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.github-copilot-cli ];
  };
}
