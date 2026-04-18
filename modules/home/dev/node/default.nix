{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.dev.node;
  nodejs = pkgs.nodejs;
in
{
  options.${namespace}.dev.node = {
    enable = mkBoolOpt false "Enable Node.js toolchain (nodejs, pnpm, yarn, bun, esbuild)";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      nodejs
      (pnpm.override { inherit nodejs; })
      (yarn.override { inherit nodejs; })
      bun
      esbuild
    ];
  };
}
