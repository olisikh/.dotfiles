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
    services = {
      skhd = {
        enable = true;
        skhdConfig = ''
          # focus window
          shift + ctrl - h : yabai -m window --focus west
          shift + ctrl - j : yabai -m window --focus south
          shift + ctrl - k : yabai -m window --focus north
          shift + ctrl - l : yabai -m window --focus east

          # swap managed window
          shift + ctrl + alt - h : yabai -m window --swap west
          shift + ctrl + alt - j : yabai -m window --swap south
          shift + ctrl + alt - k : yabai -m window --swap north
          shift + ctrl + alt - l : yabai -m window --swap east

          # move managed window
          shift + alt - h : yabai -m window --warp west
          shift + alt - j : yabai -m window --warp south
          shift + alt - k : yabai -m window --warp north
          shift + alt - l : yabai -m window --warp east

          # rotate tree
          shift + alt - r : yabai -m space --rotate 90

          # toggle window fullscreen zoom
          shift + alt - f : yabai -m window --toggle zoom-fullscreen

          # toggle padding and gap
          shift + alt - g : yabai -m space --toggle padding; yabai -m space --toggle gap

          # float / unfloat window and center on screen
          shift + alt - t : yabai -m window --toggle float;\
                    yabai -m window --grid 4:4:1:1:2:2

          # toggle window split type
          shift + alt - e : yabai -m window --toggle split

          # balance size of windows
          shift + alt - 0 : yabai -m space --balance

          # move window and focus desktop
          shift + alt - 1 : yabai -m window --space 1; yabai -m space --focus 1
          shift + alt - 2 : yabai -m window --space 2; yabai -m space --focus 2
          shift + alt - 3 : yabai -m window --space 3; yabai -m space --focus 3
          shift + alt - 4 : yabai -m window --space 4; yabai -m space --focus 4
          shift + alt - 5 : yabai -m window --space 5; yabai -m space --focus 5
          shift + alt - 6 : yabai -m window --space 6; yabai -m space --focus 6
          shift + alt - 7 : yabai -m window --space 7; yabai -m space --focus 7
          shift + alt - 8 : yabai -m window --space 8; yabai -m space --focus 8
          shift + alt - 9 : yabai -m window --space 9; yabai -m space --focus 9

          # create desktop, move window and follow focus - uses jq for parsing json (brew install jq)
          shift + alt - n : yabai -m space --create && \
                             index="$(yabai -m query --spaces --display | jq 'map(select(."native-fullscreen" == 0))[-1].index')" && \
                             yabai -m window --space "''${index}" && \
                             yabai -m space --focus "''${index}"

          # fast focus desktop
          shift + alt - 0 : yabai -m space --focus recent

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
  };

}
