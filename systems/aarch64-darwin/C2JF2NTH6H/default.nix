{ lib, namespace, ... }:
let
  inherit (lib.${namespace}) enabled;

  username = "olisikh";
in
{
  nix.enable = false;

  olisikh = {
    user = {
      enable = true;
      inherit username;
    };
    homebrew = {
      enable = true;
      brews = [ ];
      casks = [ ];
      taps = [ ];
    };
    services = {
      jankyborders = enabled;
      yabai = enabled;
      sketchybar = enabled;
      skhd = enabled;
      colima = enabled;
      ollama = enabled;
    };
  };

  system = {
    primaryUser = username;

    # nix-darwin state version, DO NOT TOUCH!
    stateVersion = 6;
  };
}
