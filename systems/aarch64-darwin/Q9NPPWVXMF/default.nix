{ lib, namespace, ... }:
let
  inherit (lib.${namespace}) enabled disabled;

  username = "O.Lisikh";
in
{
  olisikh = {
    # NOTE: Determinate nix distro can't be managed by nix-darwin, hence disabled
    nix = disabled;

    user = {
      inherit username;
      enable = true;
    };
    homebrew = enabled;
    services = {
      jankyborders = enabled;
      yabai = enabled;
      sketchybar = enabled;
      skhd = enabled;
      colima = enabled;
    };
  };

  system = {
    primaryUser = username;

    # nix-darwin state version, DO NOT TOUCH!
    stateVersion = 6;
  };
}
