{ pkgs, config, username, inputs, ... }:
{
  system.stateVersion = 6;

  nix.enable = false;

  # nix.extraOptions = ''
  #   auto-optimise-store = true
  #   experimental-features = nix-command flakes
  #   extra-platforms = x86_64-darwin aarch64-darwin
  # '';

  system = {
    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToEscape = true;
    };

    defaults = {
      ".GlobalPreferences"."com.apple.mouse.scaling" = 2.0;
      spaces.spans-displays = false;
      universalaccess = {
        # FIXME: cannot write universal access
        # reduceMotion = true;
        # reduceTransparency = true;
      };

      WindowManager.EnableTiledWindowMargins = true;

      dock = {
        autohide = true;
        autohide-delay = 0.0;
        autohide-time-modifier = 0.0;
        orientation = "bottom";
        dashboard-in-overlay = true;
        largesize = 85;
        tilesize = 50;
        magnification = true;
        launchanim = false;
        mru-spaces = false;
        show-recents = false;
        show-process-indicators = false;
        static-only = true;
      };

      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        CreateDesktop = false;
        FXDefaultSearchScope = "SCcf"; # current folder
        QuitMenuItem = true;
      };

      NSGlobalDomain = {
        _HIHideMenuBar = true;
        AppleFontSmoothing = 0;
        AppleInterfaceStyle = "Dark";
        AppleKeyboardUIMode = 3;
        AppleScrollerPagingBehavior = true;
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
        InitialKeyRepeat = 10;
        KeyRepeat = 2;
        NSAutomaticSpellingCorrectionEnabled = false;
        NSAutomaticWindowAnimationsEnabled = false;
        NSWindowResizeTime = 0.0;
        "com.apple.sound.beep.feedback" = 0;
        "com.apple.trackpad.scaling" = 2.0;
      };
    };
  };

  services = {
    # https://mynixos.com/nix-darwin/options/services.jankyborders
    jankyborders = {
      enable = true;
      active_color = "0xffe1e3e4";
      inactive_color = "0xff494d64";
      width = 10.0;
    };

    yabai = {
      enable = true;
      config = {
        mouse_follows_focus = "off";
        focus_follows_mouse = "autoraise";
        window_origin_display = "default";
        window_placement = "second_child";
        window_opacity = "off";
        window_shadow = "on";
        window_opacity_duration = 0.0;
        active_window_opacity = 1.0;
        normal_window_opacity = 0.9;
        window_border = "off";
        window_border_width = 6;
        active_window_border_color = "0xff775759";
        normal_window_border_color = "0xff555555";
        insert_feedback_color = "0xffd75f5f";
        split_ratio = 0.5;
        auto_balance = "off";
        mouse_modifier = "fn";
        mouse_action1 = "move";
        mouse_action2 = "resize";
        mouse_drop_action = "swap";

        top_padding = 12;
        bottom_padding = 12;
        left_padding = 12;
        right_padding = 12;
        window_gap = 12;
        layout = "bsp"; # default "float" (windows are not managed)
      };
      # WARN: Yabai scription addition requires Security Integration Protection to be partially disabled.
      # 1. In OSX Recovery mode terminal (long press power button during boot) run the following command:
      # > csrutil enable --without fs --without debug --without nvram
      # 2. In normal mode enable non-Apple signed binaries:
      # > sudo nvram boot-args=-arm64e_preview_abi
      # 3. Reboot again
      enableScriptingAddition = true;
      extraConfig = ''
        # apps to not manage (ignore)
        yabai -m rule --add app="^System Preferences$" manage=off
        yabai -m rule --add app="^Archive Utility$" manage=off
        yabai -m rule --add app="^Creative Cloud$" manage=off
        yabai -m rule --add app="^Logi Options$" manage=off

        # yabai -m rule --add app="^Wally$" manage=off
        # yabai -m rule --add app="^Pika$" manage=off
        # yabai -m rule --add app="^balenaEtcher$" manage=off
        # yabai -m rule --add app="^Alfred Preferences$" manage=off

        echo "yabai configuration loaded.."
      '';
    };

    skhd = {
      enable = true;
      skhdConfig = ''
        # focus window
        shift + ctrl - h : yabai -m window --focus west
        shift + ctrl - j : yabai -m window --focus south
        shift + ctrl - k : yabai -m window --focus north
        shift + ctrl - l : yabai -m window --focus east

        # swap managed window
        shift + alt - h : yabai -m window --swap west
        shift + alt - j : yabai -m window --swap south
        shift + alt - k : yabai -m window --swap north
        shift + alt - l : yabai -m window --swap east

        # move managed window
        shift + alt + ctrl - h : yabai -m window --warp west
        shift + alt + ctrl - j : yabai -m window --warp south
        shift + alt + ctrl - k : yabai -m window --warp north
        shift + alt + ctrl - l : yabai -m window --warp east

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

    sketchybar = {
      enable = true;
      extraPackages = with pkgs; [
        lua5_4
        jq
        sketchybar-app-font
      ];
      # config = ''
      #   sketchybar --bar height=24
      #   sketchybar --update
      #   echo "sketchybar configuration loaded.."
      # '';
    };
  };

  launchd.agents = {
    "colima.default" = {
      command = "${pkgs.colima}/bin/colima start --foreground";
      serviceConfig = {
        Label = "com.colima.default";
        RunAtLoad = true;
        KeepAlive = true;

        # not sure where to put these paths and not reference a hard-coded `$HOME`; `/var/log`?
        StandardOutPath = "/var/log/colima/default/daemon/launchd.stdout.log";
        StandardErrorPath = "/var/log/colima/default/daemon/launchd.stderr.log";

        # not using launchd.agents.<name>.path because colima needs the system ones as well
        EnvironmentVariables = {
          PATH = "${pkgs.colima}/bin:${pkgs.docker}/bin:/usr/bin:/bin:/usr/sbin:/sbin";
          TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE = "/var/run/docker.sock";
          DOCKER_HOST = "unix:///Users/${username}/.colima/default/docker.sock";
        };
      };
    };
  };

  environment = {
    systemPackages = with pkgs; [
      lua5_4
      lima
      colima
      docker
      docker-compose
      sbarlua
    ];

    variables = {
      PATH = "${pkgs.colima}/bin:${pkgs.docker}/bin:/usr/bin:/bin:/usr/sbin:/sbin";
      TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE = "/var/run/docker.sock";
      DOCKER_HOST = "unix:///Users/${username}/.colima/default/docker.sock";
    };
  };

  security.pam.enableSudoTouchIdAuth = true;

  users.users.${username} = {
    home = "/Users/${username}";
  };

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "zap";
    };
    brews = [ ];
    casks = [
      "raycast"
    ];
    taps = [
      "homebrew/bundle"
      "homebrew/services"
    ];
  };
}
