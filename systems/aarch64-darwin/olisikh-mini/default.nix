{ lib, namespace, pkgs, ... }:
let
  inherit (lib.${namespace}) enabled disabled;

  username = "olisikh";
  hostName = "olisikh-mini";
  localHostName = hostName;
in
{
  olisikh = {
    # NOTE: Install Determinate Nix, don't rely on Darwin to manage Nix
    nix = disabled;

    user = {
      enable = true;
      inherit username;
    };
    homebrew = {
      enable = true;
      brews = [ ];
      casks = [
        "ollama-app"
        "iina"
        "claude-code"
        "codex"
        "chatgpt"
      ];
      taps = [ ];
    };
    services = {
      jankyborders = disabled;
      yabai = disabled;
      sketchybar = disabled;
      skhd = disabled;
      colima = enabled;
      ollama = enabled;
      tailscale = enabled;
    };
  };

  networking = {
    inherit hostName localHostName;

    computerName = "Oleksii's Mac Mini";
  };

  environment = {
    systemPackages = with pkgs; [
      cocoapods
    ];
  };

  system = {
    primaryUser = username;

    # nix-darwin state version, DO NOT TOUCH!
    stateVersion = 6;
  };
}
