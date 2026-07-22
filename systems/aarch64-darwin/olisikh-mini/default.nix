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
      macmon = enabled;
      jankyborders = enabled;
      yabai = enabled;
      skhd = enabled;
      handy = enabled;
      sketchybar = enabled;
      raycast = enabled;
      betterdisplay = enabled;
      codexbar = enabled;
      repobar = enabled;
      bitwarden = enabled;
      peekaboo = enabled;
      telegram = enabled;
    };

    media.spotify = enabled;

    services.plane = {
      enable = true;
      productionActive = false;
      hermesUserId = "0ba31c66-78f1-4391-9e73-c64445ca2cb2";
      e2e.projectId = "075a4b66-ae4d-423a-a46f-817e69602a46";
      canary.enable = false;
    };

    services.vikunja = {
      enable = true;
      productionActive = true;
    };

    containers.colima = enabled;

    ai = {
      ollama = enabled;
      voicebox = enabled;
      codex = enabled;
      chatgpt = enabled;
    };

    network = {
      tailscale = {
        enable = true;
        caddy = {
          enable = true;
          rootRedirect = "/hermes-webui/";
          webui.enable = true;
          plane.enable = false;
          vikunja.enable = true;
          openclaw.enable = true;
        };
        golink = enabled;
      };
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
