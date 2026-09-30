{ config, lib, ... }:
let
  userCfg = config.olisikh.core.user;
in
{
  imports = [ ../olisikh-mini/default.nix ];
  _module.args.profile = "boring";

  # Snowfall derives the flake configuration name as a hostname. This alias
  # selects a profile only; it must not rename the physical Mac mini.
  networking.hostName = lib.mkForce "olisikh-mini";
  networking.localHostName = lib.mkForce "olisikh-mini";

  # The disabled yabai/skhd modules remove their agents on every host.
  # Also stop AeroSpace when switching from the normal mini to boring.
  system.activationScripts.postActivation.text = lib.mkAfter ''
    uid="$(id -u -- ${userCfg.username})"
    label="org.nixos.aerospace"
    agent="${userCfg.home}/Library/LaunchAgents/$label.plist"

    echo "==> Boring profile cleanup: unloading $label"
    launchctl asuser "$uid" sudo --user=${userCfg.username} -- \
      launchctl bootout "gui/$uid/$label" 2>/dev/null || true
    launchctl asuser "$uid" sudo --user=${userCfg.username} -- \
      launchctl unload "$agent" 2>/dev/null || true
    rm -f "$agent"
  '';
}
