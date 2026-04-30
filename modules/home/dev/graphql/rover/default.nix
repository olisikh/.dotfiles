{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.dev.graphql.rover;
in
{
  options.${namespace}.dev.graphql.rover = {
    enable = mkBoolOpt false "Enable rover";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      rover
    ];
  };
}
