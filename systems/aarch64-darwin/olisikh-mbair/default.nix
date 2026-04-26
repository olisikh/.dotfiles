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
        inherit username;
        enable = true;
      };

      homebrew = {
        enable = true;
        brews = [ "pinentry-mac" "JetBrains/utils/kotlin-lsp" ];
      };
    };

    desktop = {
      jankyborders = enabled;
      yabai = enabled;
      skhd = enabled;
    };

    apps = {
      sketchybar = enabled;
      raycast = enabled;
      betterdisplay = enabled;
      codexbar = enabled;
      discord = enabled;
      telegram = enabled;
    };

    media.spotify = enabled;

    containers.colima = enabled;

    ai = {
      ollama = enabled;
      claude-code = enabled;
      codex = enabled;
      chatgpt = enabled;
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
