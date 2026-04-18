{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.editor.obsidian;
in
{
  options.${namespace}.editor.obsidian = {
    enable = mkBoolOpt false "Enable obsidian (note-taking app)";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.obsidian ];
  };
}
