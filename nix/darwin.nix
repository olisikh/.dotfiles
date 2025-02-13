{ pkgs, config, username, inputs, ... }:
{
  system.stateVersion = 6;

  nix = {
    enable = false;
    # extraOptions = ''
    # auto-optimise-store = true
    # experimental-features = nix-command flakes
    # extra-platforms = x86_64-darwin aarch64-darwin
    # '';
  };

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
        _HIHideMenuBar = false;
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

    sketchybar = {
      enable = true;
      extraPackages = with pkgs; [ jq gh ];
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
    casks = [ ];
    taps = [
      # default
      "homebrew/bundle"
      "homebrew/services"
      # custom
      "FelixKratz/formulae" # borders
      # "databricks/tap" # databricks
      # "pkgxdev/made" # pkgx
      # "nikitabobko/tap" # aerospace
    ];
  };
}
