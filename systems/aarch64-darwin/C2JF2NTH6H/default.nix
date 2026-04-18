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
        enable = true;
        inherit username;
      };
    };

    core.homebrew = {
      enable = true;
      brews = [ ];
      casks = [ ];
      taps = [ ];
    };

    desktop = {
      jankyborders = enabled;
      yabai = enabled;
      skhd = enabled;
    };

    gui = {
      sketchybar = enabled;
      raycast = enabled;
      betterdisplay = enabled;
      codexbar = enabled;
      iina = enabled;
    };

    containers.colima = enabled;
    ai = {
      ollama = enabled;
      claude-code = enabled;
      codex = enabled;
      chatgpt = enabled;
    };
  };

  system = {
    primaryUser = username;

    # nix-darwin state version, DO NOT TOUCH!
    stateVersion = 6;
  };
}
