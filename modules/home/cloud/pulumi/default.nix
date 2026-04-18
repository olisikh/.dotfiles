{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.cloud.pulumi;
in
{
  options.${namespace}.cloud.pulumi = {
    enable = mkBoolOpt false "Enable Pulumi (infrastructure as code tool for cloud deployments)";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      (pulumi.withPackages (ps: with ps; [
        pulumi-nodejs
      ]))
    ];
  };
}
