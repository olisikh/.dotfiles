{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt mkOptRequired;

  cfg = config.${namespace}.user;

  defaultHomeDir = config.snowfallorg.users."${cfg.username}".home.path;
in
{
  options.${namespace}.user = with types; {
    enable = mkBoolOpt false "Enable darwin user module";
    username = mkOptRequired str "Name of the user";
    home = mkOpt str defaultHomeDir "Home directory of the user";
  };

  config = mkIf cfg.enable {
    system = {
      keyboard = {
        enableKeyMapping = true;
        remapCapsLockToEscape = true;
      };

      defaults = {
        ".GlobalPreferences" = {
          "com.apple.mouse.scaling" = 2.0;
        };

        spaces.spans-displays = false;

        # WARN: fails on work mac, probably stopped working after OSX upgrade
        # universalaccess = {
        #   reduceMotion = true;
        #   reduceTransparency = true;
        # };

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
          AppleSpacesSwitchOnActivate = false;
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

        CustomUserPreferences = {
          "com.apple.symbolichotkeys" = {
            AppleSymbolicHotKeys = {
              # 60: Select the previous input source (⌘ Space)
              "60" = {
                enabled = true;
                value = {
                  parameters = [
                    32
                    49
                    1048576
                  ];
                  type = "standard";
                };
              };

              # 61: Select next source in Input menu (⌘⌥ Space)
              "61" = {
                enabled = true;
                value = {
                  parameters = [
                    32
                    49
                    1572864
                  ];
                  type = "standard";
                };
              };

              # 64: Spotlight search (disable)
              "64" = {
                enabled = false;
              };

              # 65: Finder search window / Spotlight finder search (disable)
              "65" = {
                enabled = false;
              };
            };
          };
        };
      };
    };

    security.pam.services.sudo_local.touchIdAuth = true;

    users.users."${cfg.username}" = {
      home = cfg.home;
      shell = pkgs.zsh;
    };
  };
}
