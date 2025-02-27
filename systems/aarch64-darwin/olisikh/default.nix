{ config, lib, namespace, ... }:
let

  inherit (lib.${namespace}) enabled;
in
{
  olisikh = {
    user = enabled;
    services = {
      jankyborders = enabled;
      yabai = enabled;
      sketchybar = enabled;
      skhd = enabled;
    };
  };

  networking = {
    computerName = "Oleksii's MacBook Air";
    hostName = "olisikh";
    localHostName = "olisikh";
  };
}
