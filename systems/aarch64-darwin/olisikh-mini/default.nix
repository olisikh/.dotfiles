{
  lib,
  namespace,
  pkgs,
  profile,
  ...
}:
let
  inherit (lib.${namespace}) enabled disabled;

  # Profile-specific overrides stay under the project namespace. Add whole
  # feature overrides here rather than creating independent per-option maps.
  profiles = {
    default = {
      apps = {
        yabai = enabled;
        instant-space-switcher = enabled;
      };
    };
    boring = {
      apps = {
        yabai = disabled;
        instant-space-switcher = disabled;
      };
    };
  };

  username = "olisikh";
  hostName = "olisikh-mini";
  computerName = "Oleksii's Mac Mini";
  base = {
    nix.enable = false;

    olisikh = {
      core = {
        user = {
          inherit username;
          enable = true;
        };
        homebrew = enabled;
      };

      security.pinentry-mac = enabled;

      fonts = {
        sf-symbols = enabled;
        sf-pro = enabled;
        sf-mono = enabled;
      };

      apps = {
        macmon = enabled;
        jankyborders = enabled;
        skhd = enabled;
        handy = enabled;
        sketchybar = enabled;
        raycast = enabled;
        betterdisplay = enabled;
        codexbar = enabled;
        repobar = enabled;
        bitwarden = enabled;
        brave = enabled;
        peekaboo = enabled;
        telegram = enabled;
        obsidian = {
          enable = true;
          backend.enable = false;
        };
      };

      media.spotify = enabled;

      productivity.vikunja = {
        enable = true;
        productionActive = true;
        mcp.enable = true;
        hermesBot = {
          enable = true;
          botUserId = 3;
        };
      };

      containers.colima = enabled;

      dev.kotlin-lsp = enabled;

      ai = {
        qmd = enabled;
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
            vikunja = {
              enable = true;
              hermesWebhook.enable = true;
            };
            openclaw.enable = true;
          };
          golink = enabled;
        };
        clearvpn = enabled;
      };
    };

    # Moshi uses this host's normal SSH server; the daemon adds Easy Pair,
    # Herdr detection, and agent-event delivery without exposing a web port.
    homebrew.brews = [
      "mosh"
      {
        name = "rjyo/moshi/moshi-hook";
        trusted = true;
      }
    ];

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
  };
in
lib.recursiveUpdate base {
  olisikh = profiles.${profile};
}
