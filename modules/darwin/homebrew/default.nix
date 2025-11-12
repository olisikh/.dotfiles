{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.homebrew;
in
{
  options.${namespace}.homebrew = {
    enable = mkBoolOpt false "Enable homebrew darwin module";
  };

  config = mkIf cfg.enable {
    homebrew = {
      enable = true;
      onActivation = {
        autoUpdate = false;
        upgrade = false;
        cleanup = "zap";
      };
      brews = [ ];
      casks = [
        "raycast"
        "betterdisplay"
        "zen"
      ];
      taps = [
        "homebrew/bundle"
        "homebrew/services"
      ];
    };

    environment.systemPath = [ "/opt/homebrew/bin" ];
  };
}
