{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.dev.shell.ripgrep;
in
{
  options.${namespace}.dev.shell.ripgrep = {
    enable = mkBoolOpt false "Enable ripgrep (rg - fast grep alternative with git integration)";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.ripgrep ];
  };
}
