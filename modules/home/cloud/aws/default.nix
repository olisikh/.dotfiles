{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.cloud.aws;
in
{
  options.${namespace}.cloud.aws = {
    enable = mkBoolOpt false "Enable AWS CLI";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.awscli2 ];
  };
}
