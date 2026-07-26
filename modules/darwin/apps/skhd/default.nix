{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf optionalString;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.apps.skhd;
  yabaiCfg = config.${namespace}.apps.yabai;
  userCfg = config.${namespace}.core.user;
  # handyCfg = config.${namespace}.apps.handy;

  # Stable path on the filesystem that macOS TCC keys on. nix store paths
  # change every rebuild, which silently revokes Accessibility / Input
  # Monitoring permission for skhd. Copying the binary to a fixed path
  # keeps TCC stable across rebuilds.
  stableBin = "/usr/local/bin/skhd";

  # Yabai keymaps - only included when yabai is enabled
  yabaiKeymaps = optionalString yabaiCfg.enable ''
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

  # handyKeymaps = optionalString handyCfg.enable ''
  #   # toggle transcription
  #   ctrl - space : handy --toggle-transcription
  # '';
in
{
  options.${namespace}.apps.skhd = {
    enable = mkBoolOpt false "Enable skhd module";

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Additional skhd configuration to append.";
    };
  };

  config = mkIf cfg.enable {
    services.skhd = {
      enable = true;
      skhdConfig = lib.concatStringsSep "\n" [
        yabaiKeymaps
        # handyKeymaps
        cfg.extraConfig
      ];
    };

    # Pin skhd to a stable path so macOS TCC (Accessibility / Input Monitoring)
    # does not revoke permission on every nix rebuild. Only re-copy + re-sign
    # when the binary content actually changes. nix-darwin only invokes the
    # named activation hooks (preActivation / extraActivation / postActivation);
    # `types.lines` merges this with other modules' contributions automatically.
    system.activationScripts.extraActivation.text = ''
      # skhd stable-bin: keep TCC (Accessibility / Input Monitoring) stable across rebuilds
      __skhd_src="${config.services.skhd.package}/bin/skhd"
      __skhd_dst="${stableBin}"
      if [ -f "$__skhd_dst" ] && [ "$(shasum -a 256 "$__skhd_src" | cut -d' ' -f1)" = "$(shasum -a 256 "$__skhd_dst" | cut -d' ' -f1)" ]; then
        :
      else
        install -m 0755 "$__skhd_src" "$__skhd_dst"
        codesign --force --sign - "$__skhd_dst" 2>/dev/null || true
      fi
    '';

    # Point launchd at the stable binary so TCC keys on it.
    launchd.user.agents.skhd.serviceConfig.ProgramArguments =
      lib.mkForce [ "${stableBin}" "-c" "/etc/skhdrc" ];

    # After userLaunchd has (re)loaded the agent, check whether skhd actually
    # stayed alive. If it exit-looped, the most likely cause is that the binary
    # content changed (real version bump) and macOS revoked Accessibility /
    # Input Monitoring. Open the Privacy pane + post a notification.
    system.activationScripts.postActivation.text = ''
      __skhd_user="${userCfg.username}"
      __skhd_uid="$(id -u -- "$__skhd_user" 2>/dev/null || true)"
      if [ -n "$__skhd_uid" ]; then
        sleep 2
        if ! launchctl asuser "$__skhd_uid" pgrep -x skhd >/dev/null 2>&1; then
          launchctl asuser "$__skhd_uid" sudo -u "$__skhd_user" \
            open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility" 2>/dev/null || true
          launchctl asuser "$__skhd_uid" sudo -u "$__skhd_user" \
            /usr/bin/osascript -e 'display notification "skhd is not running. Re-grant Accessibility / Input Monitoring in System Settings → Privacy & Security (look for /usr/local/bin/skhd)." with title "nix-darwin" subtitle "skhd needs Accessibility / Input Monitoring"' 2>/dev/null || true
          echo "warning: skhd not running after activation — likely needs Accessibility / Input Monitoring re-grant" >&2
        fi
      fi
    '';
  };
}
