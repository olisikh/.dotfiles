{ config, lib, namespace, ... }:
let
  inherit (lib.${namespace}) enabled disabled;
in
{
  olisikh = {
    # NOTE: determinate nix distro can't be managed by nix-darwin, hence disabled
    nix = disabled;
    user = enabled;
    services = {
      jankyborders = enabled;
      yabai = enabled;
      sketchybar = enabled;
      skhd = enabled;
      colima = enabled;
    };
  };

  networking = {
    computerName = "Oleksii's MacBook Air";
    hostName = "olisikh";
    localHostName = "olisikh";
  };

  # nix-darwin state version, DO NOT TOUCH!
  system.stateVersion = 6;
}
