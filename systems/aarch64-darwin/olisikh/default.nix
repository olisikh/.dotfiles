{ config, lib, namespace, ... }:
let

  inherit (lib.${namespace}) enabled;
in
{
  olisikh = {
    user = enabled;
  };

  networking = {
    computerName = "Oleksii's MacBook Air";
    hostName = "olisikh";
    localHostName = "olisikh";
  };
}
