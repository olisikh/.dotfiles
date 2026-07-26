{ lib, ... }:
with lib;
rec {
  mkOptRequired = type: desc:
    mkOption {
      inherit type;
      description = desc;
    };

  mkOptRequired' = type:
    mkOption {
      inherit type;
    };

  mkOpt = type: default: desc:
    mkOption {
      inherit type default;
      description = desc;
    };

  mkOpt' = type: default: mkOpt type default null;

  mkBoolOpt = mkOpt types.bool;

  mkBoolOpt' = mkOpt' types.bool;

  enabled = {
    enable = true;
  };

  disabled = {
    enable = false;
  };

  # Pin a nix-managed macOS daemon binary to a stable path so macOS TCC
  # (Accessibility / Input Monitoring) does not revoke permission on every
  # nix rebuild (nix store paths change, TCC keys on the path).
  #
  # Returns an attrset with the three config keys needed to:
  #   1. copy + adhoc re-sign the binary during extraActivation (sha256-guarded)
  #   2. point the launchd agent at the stable binary
  #   3. detect exit-loops after the agent reloads and notify the user
  #
  # Merge the result into `config` with `mkMerge [ (mkStableBinTCC { ... }) ]`.
  #
  # Arguments (attrset):
  #   src       - store path to the original binary (e.g. "${cfg.package}/bin/yabai")
  #   dst       - stable filesystem path (e.g. "/usr/local/bin/yabai")
  #   agent     - launchd user agent label (e.g. "yabai")
  #   procName  - process name pgrep matches (e.g. "yabai")
  #   username  - primary user name (for launchctl asuser / notifications)
  #   permLabel - what to re-grant, shown in the notification
  #   programArgs - full ProgramArguments list with dst as argv[0]
  #   envVars     - optional attrset for EnvironmentVariables (mkForce'd)
  mkStableBinTCC =
    { src
    , dst
    , agent
    , procName
    , username
    , permLabel
    , programArgs
    , envVars ? null
    }:
    let
      uidOf = "$(id -u -- \"${username}\" 2>/dev/null || true)";
      notify =
        "display notification \"${procName} is not running. Re-grant ${permLabel} "
        + "in System Settings → Privacy & Security (look for ${dst}).\" "
        + "with title \"nix-darwin\" subtitle \"${procName} needs ${permLabel}\"";
    in
    {
      # 1. Copy + re-sign the binary to a stable path (sha256-guarded so
      #    unchanged rebuilds are a no-op).
      system.activationScripts.extraActivation.text = ''
        __src="${src}"
        __dst="${dst}"
        if [ -f "$__dst" ] && [ "$(shasum -a 256 "$__src" | cut -d' ' -f1)" = "$(shasum -a 256 "$__dst" | cut -d' ' -f1)" ]; then
          :
        else
          install -m 0755 "$__src" "$__dst"
          codesign --force --sign - "$__dst" 2>/dev/null || true
        fi
      '';

      # 2. Point launchd at the stable binary so TCC keys on it.
      launchd.user.agents.${agent}.serviceConfig =
        if envVars == null
        then { ProgramArguments = mkForce programArgs; }
        else {
          ProgramArguments = mkForce programArgs;
          EnvironmentVariables = mkForce envVars;
        };

      # 3. After userLaunchd reloads the agent, check whether the process
      #    stayed alive. If it exit-looped (binary changed, TCC revoked),
      #    open the Accessibility pane + post a notification.
      system.activationScripts.postActivation.text = ''
        __user="${username}"
        __uid=${uidOf}
        if [ -n "$__uid" ]; then
          sleep 2
          if ! launchctl asuser "$__uid" pgrep -x ${procName} >/dev/null 2>&1; then
            launchctl asuser "$__uid" sudo -u "$__user" \
              open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility" 2>/dev/null || true
            launchctl asuser "$__uid" sudo -u "$__user" \
              /usr/bin/osascript -e '${notify}' 2>/dev/null || true
            echo "warning: ${procName} not running after activation — likely needs ${permLabel} re-grant" >&2
          fi
        fi
      '';
    };
}
