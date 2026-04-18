{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.media.tools;
in
{
  options.${namespace}.media.tools = {
    enable = mkBoolOpt false "Enable media tools (ffmpeg, pngpaste, bchunk, dos2unix)";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      ffmpeg
      pngpaste
      bchunk
      dos2unix
    ];
  };
}
