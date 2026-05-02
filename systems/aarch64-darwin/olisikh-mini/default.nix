{ lib, namespace, pkgs, ... }:
let
  inherit (lib.${namespace}) enabled;

  username = "olisikh";
  hostName = "olisikh-mini";
  computerName = "Oleksii's Mac Mini";
in
{
  nix.enable = false;

  olisikh = {
    core = {
      user = {
        inherit username;
        enable = true;
      };
      homebrew = enabled;
    };

    fonts = {
      sf-symbols = enabled;
      sf-pro = enabled;
      sf-mono = enabled;
    };

    apps = {
      jankyborders = enabled;
      yabai = enabled;
      skhd = enabled;
      handy = enabled;
      sketchybar = enabled;
      raycast = enabled;
      betterdisplay = enabled;
      codexbar = enabled;
      telegram = enabled;
    };

    media.spotify = enabled;

    containers.colima = enabled;

    ai = {
      ollama = enabled;
      codex = enabled;
    };

    network = {
      tailscale = enabled;
      clearvpn = enabled;
    };
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
