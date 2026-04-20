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

    desktop = {
      jankyborders = enabled;
      yabai = enabled;
      skhd = enabled;
    };

    apps = {
      sketchybar = enabled;
      raycast = enabled;
      betterdisplay = enabled;
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
