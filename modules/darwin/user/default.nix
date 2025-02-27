{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.user;
in
{
  options.${namespace}.user = with types; {
    enable = mkBoolOpt false "Enable shared darwin module";
    name = mkOpt str "olisikh" "Name of the user";
  };

  config = mkIf cfg.enable {
    nix.enable = false;

    # nix.extraOptions = ''
    #   auto-optimise-store = true
    #   experimental-features = nix-command flakes
    #   extra-platforms = x86_64-darwin aarch64-darwin
    # '';

    snowfallorg.users.${cfg.name}.home.config = {
      home = {
        file = {
          ".profile".text = ''
            # The default file limit is far too low and throws an error when rebuilding the system.
            # See the original with: ulimit -Sa
            ulimit -n 4096
          '';
        };
      };
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
            DOCKER_HOST = "unix:///Users/${cfg.name}/.colima/default/docker.sock";
          };
        };
      };
    };

    environment = {
      systemPath = [ "/opt/homebrew/bin" ];

      systemPackages = with pkgs; [
        lua5_4
        lima
        colima
        docker
        docker-compose
      ];

      variables = {
        # TODO: Is there a better way to extend path in nix-darwin?
        PATH = builtins.concatStringsSep ":" [
          "${pkgs.colima}/bin"
          "${pkgs.docker}/bin"
          "/usr/bin"
          "/bin"
          "/usr/sbin"
          "/sbin"
          ''''${PATH}''
        ];
        TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE = "/var/run/docker.sock";
        DOCKER_HOST = "unix:///Users/${cfg.name}/.colima/default/docker.sock";
      };
    };

    security.pam.services.sudo_local.touchIdAuth = true;

    users.users.${cfg.name} = {
      home = "/Users/${cfg.name}";
      shell = pkgs.zsh;
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

    system.stateVersion = 6;
  };
}
