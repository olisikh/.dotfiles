{ lib, config, namespace, pkgs, ... }:
with lib;
let
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.dev.virtualization.qemu;

  arch = if pkgs.stdenv.hostPlatform.isAarch64 then "aarch64"
    else if pkgs.stdenv.hostPlatform.isx86_64 then "x86_64"
    else throw "Unsupported architecture: ${pkgs.stdenv.hostPlatform.system}";
in
{
  options.${namespace}.dev.virtualization.qemu = {
    enable = mkBoolOpt false "Enable qemu module";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.qemu ];

    home.file.".local/bin/qemu" = {
      source = "${pkgs.qemu}/bin/qemu-system-${arch}";
      executable = true;
    };
  };
}
