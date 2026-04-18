{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.dev.python;
in
{
  options.${namespace}.dev.python = {
    enable = mkBoolOpt false "Enable Python toolchain";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      (python3.withPackages (ps: with ps; [
        pytest
        debugpy
      ]))
    ];
  };
}
