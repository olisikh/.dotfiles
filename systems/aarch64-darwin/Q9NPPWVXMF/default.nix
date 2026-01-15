{ lib, namespace, ... }:
let
  inherit (lib.${namespace}) enabled disabled;

  username = "O.Lisikh";
in
{
  olisikh = {
    # NOTE: Install Determinate Nix, don't rely on Darwin to manage Nix
    nix = disabled;

    user = {
      enable = true;
      inherit username;
    };
    homebrew.work = enabled;
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
