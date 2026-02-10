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
      ] ++ (optionals cfg.personal.enable [
        "jetbrains/utils/kotlin-lsp"
      ]);

      casks = [ "raycast" "betterdisplay" ] ++
        (optionals cfg.personal.enable [
          "intellij-idea"
          "intellij-idea-ce"
          "ollama-app"
          "iina"
        ]) ++
        (optionals cfg.work.enable [
          # Add work-specific casks here
        ]);
    };

    environment.systemPath = [ "/opt/homebrew/bin" ];
  };
}
