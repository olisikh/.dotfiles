{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.apps.jankyborders;
  svcCfg = config.services.jankyborders;
  userCfg = config.${namespace}.core.user;

  # Stable path on the filesystem that macOS TCC keys on. nix store paths
  # change every rebuild, which silently revokes Accessibility permission for
  # borders. Copying the binary to a fixed path keeps TCC stable across rebuilds.
  stableBin = "/usr/local/bin/borders";

  # Reconstruct the borders arg list the same way nix-darwin's
  # services.jankyborders module does, but with the stable binary as argv[0].
  joinStrings = strings: builtins.concatStringsSep "," strings;

  optionalArg = arg: value:
    if value != null && value != ""
    then
      if lib.isList value
      then lib.map (val: "${arg}=${val}") value
      else [ "${arg}=${value}" ]
    else [];

  bordersArgs =
    optionalArg "width" (toString svcCfg.width)
    ++ optionalArg "hidpi" (if svcCfg.hidpi then "on" else "off")
    ++ optionalArg "active_color" svcCfg.active_color
    ++ optionalArg "inactive_color" svcCfg.inactive_color
    ++ optionalArg "background_color" svcCfg.background_color
    ++ optionalArg "style" svcCfg.style
    ++ optionalArg "blur_radius" (toString svcCfg.blur_radius)
    ++ optionalArg "ax_focus" (if svcCfg.ax_focus then "on" else "off")
    ++ optionalArg "blacklist" (joinStrings svcCfg.blacklist)
    ++ optionalArg "whitelist" (joinStrings svcCfg.whitelist)
    ++ optionalArg "order" svcCfg.order;
in
{
  options.${namespace}.apps.jankyborders = {
    enable = mkBoolOpt false "Enable jankyborders module";
  };

  config = mkIf cfg.enable {
    services.jankyborders = {
      enable = true;
      active_color = "0xff7aa2f7"; # red: 0xfff7768e, white: 0xffe1e3e4, blue: 0xff7aa2f7
      inactive_color = "0xff494d64";
      width = 10.0;
    };

    # Pin borders to a stable path so macOS TCC (Accessibility) does not revoke
    # permission on every nix rebuild. Only re-copy + re-sign when the binary
    # content actually changes. nix-darwin only invokes the named activation
    # hooks (preActivation / extraActivation / postActivation); `types.lines`
    # merges this with other modules' contributions automatically.
    system.activationScripts.extraActivation.text = ''
      # borders stable-bin: keep TCC (Accessibility) stable across rebuilds
      __borders_src="${svcCfg.package}/bin/borders"
      __borders_dst="${stableBin}"
      if [ -f "$__borders_dst" ] && [ "$(shasum -a 256 "$__borders_src" | cut -d' ' -f1)" = "$(shasum -a 256 "$__borders_dst" | cut -d' ' -f1)" ]; then
        :
      else
        install -m 0755 "$__borders_src" "$__borders_dst"
        codesign --force --sign - "$__borders_dst" 2>/dev/null || true
      fi
    '';

    # Point launchd at the stable binary so TCC keys on it.
    launchd.user.agents.jankyborders.serviceConfig.ProgramArguments =
      lib.mkForce ([ "${stableBin}" ] ++ bordersArgs);

    # After userLaunchd has (re)loaded the agent, check whether borders actually
    # stayed alive. If it exit-looped, the most likely cause is that the binary
    # content changed (real version bump) and macOS revoked Accessibility.
    # Open the Privacy pane + post a notification so you know to re-grant.
    system.activationScripts.postActivation.text = ''
      __borders_user="${userCfg.username}"
      __borders_uid="$(id -u -- "$__borders_user" 2>/dev/null || true)"
      if [ -n "$__borders_uid" ]; then
        sleep 2
        if ! launchctl asuser "$__borders_uid" pgrep -x borders >/dev/null 2>&1; then
          launchctl asuser "$__borders_uid" sudo -u "$__borders_user" \
            open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility" 2>/dev/null || true
          launchctl asuser "$__borders_uid" sudo -u "$__borders_user" \
            /usr/bin/osascript -e 'display notification "borders is not running. Re-grant Accessibility in System Settings → Privacy & Security → Accessibility (look for /usr/local/bin/borders)." with title "nix-darwin" subtitle "borders needs Accessibility"' 2>/dev/null || true
          echo "warning: borders not running after activation — likely needs Accessibility re-grant" >&2
        fi
      fi
    '';
  };
}
