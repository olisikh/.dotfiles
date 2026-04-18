{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.editor.vscode;
in
{
  options.${namespace}.editor.vscode = {
    enable = mkBoolOpt false "Enable vscode (code editor)";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.vscode ];
  };
}
