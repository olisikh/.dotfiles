{ lib, namespace, pkgs, ... }:
let
  inherit (lib.${namespace}) enabled disabled;

  username = "olisikh";
  hostName = "olisikh-mbair";
  computerName = "Oleksii's MacBook Air";
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
      casks = [
        "ollama-app"
        "iina"
        "claude-code"
        "codex"
        "chatgpt"
      ];
      taps = [ ];
    };
    services = {
      jankyborders = enabled;
      yabai = enabled;
      sketchybar = enabled;
      skhd = enabled;
      colima = enabled;
      ollama = enabled;
      tailscale = enabled;
    };
  };

  networking = {
    inherit hostName computerName;
    localHostName = hostName;
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
