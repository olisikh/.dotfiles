{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.dev.shell.eza;
in
{
  options.${namespace}.dev.shell.eza = {
    enable = lib.${namespace}.mkBoolOpt false "Enable eza (modern replacement for ls with git support and icons)";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.eza ];

    programs.zsh.initContent = lib.${namespace}.mkZshLate
      # zsh
      ''
        alias ls="exa"
        alias ll="exa -alh"
        alias tree="exa --tree"
      '';
  };
}
