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

    terminal = {
      homebrew = {
        enable = true;
        brews = [ ];
        casks = [ ];
        taps = [ ];
      };
    };

    desktop = {
      jankyborders = enabled;
      yabai = enabled;
      skhd = enabled;
    };

    gui.sketchybar = enabled;
    containers.colima = enabled;
    ai.ollama = enabled;
  };

  system = {
    primaryUser = username;

    # nix-darwin state version, DO NOT TOUCH!
    stateVersion = 6;
  };
}
