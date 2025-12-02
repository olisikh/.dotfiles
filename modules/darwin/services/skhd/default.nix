{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.services.skhd;
in
{
  options.${namespace}.services.skhd = {
    enable = mkBoolOpt false "Enable skhd module";
  };

  config = mkIf cfg.enable {
    services.skhd = {
      enable = true;
      skhdConfig = ''
        # focus window
        shift + ctrl - h : yabai -m window --focus west
        shift + ctrl - j : yabai -m window --focus south
        shift + ctrl - k : yabai -m window --focus north
        shift + ctrl - l : yabai -m window --focus east

        # move managed window (try --warp, change to --swap for different behavior)
        shift + alt - h : yabai -m window --warp west
        shift + alt - j : yabai -m window --warp south
        shift + alt - k : yabai -m window --warp north
        shift + alt - l : yabai -m window --warp east

        # rotate tree
        shift + alt - r : yabai -m space --rotate 90

        # float / unfloat window and center on screen
        shift + alt - t : yabai -m window --toggle float;\
                  yabai -m window --grid 4:4:1:1:2:2

        # toggle window split type
        shift + alt - e : yabai -m window --toggle split

        # balance size of windows
        shift + alt - 0 : yabai -m space --balance

        # focus space (desktop)
        ctrl - 1 : yabai -m space --focus 1
        ctrl - 2 : yabai -m space --focus 2
        ctrl - 3 : yabai -m space --focus 3
        ctrl - 4 : yabai -m space --focus 4
        ctrl - 5 : yabai -m space --focus 5
        ctrl - 6 : yabai -m space --focus 6
        ctrl - 7 : yabai -m space --focus 7
        ctrl - 8 : yabai -m space --focus 8
        ctrl - 9 : yabai -m space --focus 9
        ctrl - 0 : yabai -m space --focus 10

        # toggle fullscreen zoom
        shift + alt - f : yabai -m window --toggle zoom-fullscreen

        # create desktop, move window and follow focus - uses jq for parsing json (brew install jq)
        shift + alt - n : yabai -m space --create && \
                           index="$(yabai -m query --spaces --display | jq 'map(select(."native-fullscreen" == 0))[-1].index')" && \
                           yabai -m window --space "''${index}" && \
                           yabai -m space --focus "''${index}"

        # move window to space and focus
        alt + shift - 1 : yabai -m window --space 1; yabai -m space --focus 1
        alt + shift - 2 : yabai -m window --space 2; yabai -m space --focus 2
        alt + shift - 3 : yabai -m window --space 3; yabai -m space --focus 3
        alt + shift - 4 : yabai -m window --space 4; yabai -m space --focus 4
        alt + shift - 5 : yabai -m window --space 5; yabai -m space --focus 5
        alt + shift - 6 : yabai -m window --space 6; yabai -m space --focus 6
        alt + shift - 7 : yabai -m window --space 7; yabai -m space --focus 7
        alt + shift - 8 : yabai -m window --space 8; yabai -m space --focus 8
        alt + shift - 9 : yabai -m window --space 9; yabai -m space --focus 9
        alt + shift - 0 : yabai -m window --space 10; yabai -m space --focus 10

        # fast focus desktop
        # alt + shift - - : yabai -m space --focus recent

        # send window to monitor and follow focus
        shift + alt - n : yabai -m window --display next; yabai -m display --focus next
        shift + alt - p : yabai -m window --display previous; yabai -m display --focus previous

        # increase window size
        shift + alt - w : yabai -m window --resize top:0:-20
        shift + alt - d : yabai -m window --resize left:-20:0

        # decrease window size
        shift + alt - s : yabai -m window --resize bottom:0:-20
        shift + alt - a : yabai -m window --resize top:0:20
      '';
    };
  };
}
