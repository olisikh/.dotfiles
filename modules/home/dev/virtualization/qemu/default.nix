{ lib, config, namespace, pkgs, ... }:
with lib;
let
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.dev.virtualization.qemu;
in
{
  options.${namespace}.dev.virtualization.qemu = {
    enable = mkBoolOpt false "Enable qemu module";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.qemu ];

    # Symlink specific qemu binaries for Vagrantfile compatibility
    # without replacing the entire ~/.local/bin directory
    home.file.".local/bin/qemu-system-x86_64".source = "${pkgs.qemu}/bin/qemu-system-x86_64";
    home.file.".local/bin/qemu-system-aarch64".source = "${pkgs.qemu}/bin/qemu-system-aarch64";

    # Symlink qemu firmware/share directory for Vagrantfile compatibility
    home.file.".local/share/qemu" = {
      source = "${pkgs.qemu}/share/qemu";
      recursive = true;
    };
  };
}
