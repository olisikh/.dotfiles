{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.containers.podman;
in
{
  options.${namespace}.containers.podman = {
    enable = mkBoolOpt false "Enable podman (container runtime)";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.podman ];
  };
}
