{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.ai.whisper;
in
{
  options.${namespace}.ai.whisper = {
    enable = mkBoolOpt false "Enable openai-whisper (TTS/STT tool)";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.openai-whisper ];
  };
}
