{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.user;
  homeDirectory =
    if pkgs.stdenv.isDarwin then
      "/Users/${cfg.name}"
    else
      "/home/${cfg.name}";
in
{
  options.${namespace}.user = with types; {
    enable = mkBoolOpt false "Enable user darwin module";
    name = mkOpt str "olisikh" "Name of the user";
    home = mkOpt str homeDirectory "Home directory of the user";
  };

  config = mkIf cfg.enable {
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


    environment = {
      systemPath = [ "/opt/homebrew/bin" ];

      # variables = {
      # TODO: Is there a better way to extend path in nix-darwin?
      # PATH = builtins.concatStringsSep ":" [
      #   "/usr/bin"
      #   "/bin"
      #   "/usr/sbin"
      #   "/sbin"
      #   ''''${PATH}''
      # ];
      # TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE = "/var/run/docker.sock";
      # DOCKER_HOST = "unix:///Users/${cfg.name}/.colima/default/docker.sock";
      # };
    };

    security.pam.services.sudo_local.touchIdAuth = true;

    users.users.${cfg.name} = {
      home = "/Users/${cfg.name}";
      shell = pkgs.zsh;
    };
  };
}
