{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.browser.brave;
in
{
  options.${namespace}.browser.brave = {
    enable = mkBoolOpt false "Enable brave browser";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.brave ];
  };
}
