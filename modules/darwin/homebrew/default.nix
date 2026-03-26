{ lib, config, namespace, ... }:
let
  inherit (lib) optionals mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.homebrew;
in
{
  options.${namespace}.homebrew = {
    enable = mkBoolOpt false "Enable common homebrew darwin module";

    brews = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Homebrew brews to enable";
    };

    casks = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Homebrew casks to enable";
    };

    taps = lib.mkOption {
      type = lib.types.listOf lib.types.package;
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
        "opencode"
        "JetBrains/utils/kotlin-lsp"
      ] ++ cfg.brews;

      casks = [ "raycast" "betterdisplay" ] ++ cfg.casks;

      taps = cfg.taps;
    };

    environment.systemPath = [ "/opt/homebrew/bin" ];
  };
}
