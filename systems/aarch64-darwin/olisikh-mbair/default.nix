{ lib, namespace, pkgs, ... }:
let
  inherit (lib.${namespace}) enabled disabled;

  username = "olisikh";
  hostName = "olisikh-mbair";
  computerName = "Oleksii's MacBook Air";
in
{
  nix.enable = false;

  olisikh = {
    core = {
      user = {
        enable = true;
        inherit username;
      };
    };

    core.homebrew = {
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

    desktop = {
      jankyborders = enabled;
      yabai = enabled;
      skhd = enabled;
    };

    gui.sketchybar = enabled;
    containers.colima = enabled;
    ai.ollama = enabled;
    network.tailscale = enabled;
  };

  networking = {
    inherit hostName computerName;
    localHostName = hostName;
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
