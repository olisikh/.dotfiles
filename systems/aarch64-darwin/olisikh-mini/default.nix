{ lib, namespace, pkgs, ... }:
let
  inherit (lib.${namespace}) enabled;

  username = "olisikh";
  hostName = "olisikh-mini";
  computerName = "Oleksii's Mac Mini";
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
        casks = [
          "ollama-app"
          "iina"
          "claude-code"
          "codex"
          "chatgpt"
        ];
        taps = [ ];
      };
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
