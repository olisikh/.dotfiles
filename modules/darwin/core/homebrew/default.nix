{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.core.homebrew;
in
{
  options.${namespace}.core.homebrew = {
    enable = mkBoolOpt false "Enable common homebrew darwin module";

    brews = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Homebrew brews to enable";
    };

    casks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Homebrew casks to enable";
    };

    taps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Homebrew taps to enable";
    };
  };

  config = mkIf cfg.enable {
    homebrew = {
      enable = true;
      onActivation = {
        autoUpdate = false;
        upgrade = false;
        cleanup = "zap";
      };

      brews = [
        "ffmpeg"
        "tccutil"
        "JetBrains/utils/kotlin-lsp"
      ] ++ cfg.brews;

      casks = [
        "raycast"
        "betterdisplay"
        "codexbar"
      ] ++ cfg.casks;

      taps = cfg.taps;
    };

    environment.systemPath = [ "/opt/homebrew/bin" ];
  };
}
