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

  # nix-darwin can leave a removed user LaunchAgent loaded. A boring rebuild
  # explicitly stops yabai and removes its declaration before exam use.
  system.activationScripts.postActivation.text = lib.mkAfter ''
    uid="$(id -u -- ${userCfg.username})"
    agent="${userCfg.home}/Library/LaunchAgents/org.nixos.yabai.plist"

    echo "==> Boring profile cleanup: unloading org.nixos.yabai"
    launchctl asuser "$uid" sudo --user=${userCfg.username} -- \
      launchctl bootout "gui/$uid/org.nixos.yabai" 2>/dev/null || true
    launchctl asuser "$uid" sudo --user=${userCfg.username} -- \
      launchctl unload "$agent" 2>/dev/null || true
    sudo --user=${userCfg.username} -- rm -f "$agent"
  '';
}
