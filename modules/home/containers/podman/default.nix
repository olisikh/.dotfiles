{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}.zsh) mkLate;

  cfg = config.${namespace}.containers.podman;
in
{
  options.${namespace}.containers.podman = {
    enable = lib.${namespace}.mkBoolOpt false "Enable podman (container runtime)";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.podman ];

    programs.zsh.initContent = mkLate
      # zsh
      ''
        alias p="podman"
      '';
  };
}
