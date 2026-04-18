{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.dev.docker;
in
{
  options.${namespace}.dev.docker = {
    enable = mkBoolOpt false "Enable Docker tools (docker, compose, buildx, lazydocker)";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      docker
      docker-compose
      docker-buildx
      lazydocker
    ];
  };
}
