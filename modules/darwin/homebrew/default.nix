{ lib, config, namespace, ... }:
let
  inherit (lib) optionals mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.homebrew;
in
{
  options.${namespace}.homebrew = {
    enable = mkBoolOpt true "Enable common homebrew darwin module";

    personal = {
      enable = mkBoolOpt false "Enable personal homebrew darwin module";
    };

    work = {
      enable = mkBoolOpt false "Enable work homebrew darwin module";
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

      taps = [
        "homebrew/bundle"
        "homebrew/services"
      ];

      brews = [
        "tccutil"
        "JetBrains/utils/kotlin-lsp"
      ] ++
      (optionals cfg.personal.enable [ ]) ++
      (optionals cfg.work.enable [ ]);

      casks = [ "raycast" "betterdisplay" ] ++
        (optionals cfg.personal.enable [ "ollama-app" "iina" ]) ++
        (optionals cfg.work.enable [ ]);
    };

    environment.systemPath = [ "/opt/homebrew/bin" ];
  };
}
