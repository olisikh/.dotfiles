{ lib, namespace, ... }:
let
  inherit (lib.${namespace}) enabled;

  username = "olisikh";
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
      android-studio = enabled;
      sketchybar = enabled;
      betterdisplay = enabled;
      codexbar = enabled;
    };

    media.spotify = enabled;

    containers.colima = enabled;

    dev.http = {
      proxyman = enabled;
    };

    ai = {
      ollama = enabled;
    };
  };

  system = {
    primaryUser = username;

    # nix-darwin state version, DO NOT TOUCH!
    stateVersion = 6;
  };
}
