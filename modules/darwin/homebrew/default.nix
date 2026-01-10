{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.homebrew;
in
{
  options.${namespace}.homebrew = {
    common = {
      enable = mkBoolOpt true "Enable common homebrew darwin module";
    };
    personal = {
      enable = mkBoolOpt false "Enable personal homebrew darwin module";
    };
    work = {
      enable = mkBoolOpt false "Enable work homebrew darwin module";
    };
  };

  config = {
    homebrew = mkIf cfg.common.enable {
      enable = true;
      onActivation = {
        autoUpdate = false;
        upgrade = false;
        cleanup = "zap";
      };
      brews = [
        "tccutil"
      ];
      taps = [
        "homebrew/bundle"
        "homebrew/services"
      ];

      casks = with lib;
        (optionals cfg.common.enable [ "raycast" "betterdisplay" ]) ++
        (optionals cfg.personal.enable [ "ollama-app" "vivaldi" "vlc" ]) ++
        (optionals cfg.work.enable [
          # Add work-specific casks here
        ]);
    };


    environment.systemPath = mkIf cfg.common.enable [ "/opt/homebrew/bin" ];
  };
}
