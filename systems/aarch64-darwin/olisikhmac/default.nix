{ lib, namespace, pkgs, ... }:
let
  inherit (lib.${namespace}) enabled disabled;

  username = "olisikh";
  hostName = "olisikhmac";
  localHostName = hostName;
in
{
  olisikh = {
    # NOTE: Install Determinate Nix, don't rely on Darwin to manage Nix
    nix = disabled;

    user = {
      enable = true;
      inherit username;
    };
    homebrew.personal = enabled;
    services = {
      jankyborders = enabled;
      yabai = enabled;
      sketchybar = enabled;
      skhd = enabled;
      colima = enabled;
      ollama = enabled;
    };
  };

  networking = {
    inherit hostName localHostName;

    computerName = "Oleksii's MacBook Air";
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
}
