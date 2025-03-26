{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.user;

  # WARN: if config.snowfallorg is accessed here, an infinite recursion occurs
  defaultUsername = "O.Lisikh";
  defaultHomeDir =
    if pkgs.stdenv.isDarwin then
      "/Users/${cfg.username}"
    else
      "/home/${cfg.username}";
in
{
  options.${namespace}.user = with types; {
    enable = mkBoolOpt false "Enable user darwin module";
    username = mkOpt str defaultUsername "Name of the user";
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

    security.pam.services.sudo_local.touchIdAuth = true;

    users.users."${cfg.username}" = {
      home = cfg.home;
      shell = pkgs.zsh;
    };
  };
}
