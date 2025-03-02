
{ config, lib, namespace, ... }:
let
  inherit (lib.${namespace}) enabled disabled;
in
{
  olisikh = {
    # NOTE: Determinate nix distro can't be managed by nix-darwin, hence disabled
    nix = disabled;

    user = enabled;
    homebrew = enabled;
    services = {
      jankyborders = enabled;
      yabai = enabled;
      sketchybar = disabled;
      skhd = enabled;
      colima = enabled;
    };
  };

  # nix-darwin state version, DO NOT TOUCH!
  system.stateVersion = 6;
}
