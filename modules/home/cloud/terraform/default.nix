{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.cloud.terraform;
in
{
  options.${namespace}.cloud.terraform = {
    enable = mkBoolOpt false "Enable Terraform tools (terraform, tflint)";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      terraform
      tflint
    ];
  };
}
