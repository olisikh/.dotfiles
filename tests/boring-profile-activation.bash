#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

activation_script="$(
    cd "$repo_root"
    nix eval --raw '.#darwinConfigurations.olisikh-mini-boring.config.system.activationScripts.script.text'
)"

for expected in \
    'Boring profile cleanup: unloading org.nixos.yabai' \
    'launchctl bootout "gui/$uid/org.nixos.yabai"' \
    'launchctl unload "$agent"' \
    'rm -f "$agent"'; do
    if [[ "$activation_script" != *"$expected"* ]]; then
        echo "Expected boring activation script to contain: $expected" >&2
        exit 1
    fi
done

user_launchd_line="$(printf '%s\n' "$activation_script" | grep -nF 'for f in /run/current-system/user/Library/LaunchAgents/*; do' | cut -d: -f1)"
cleanup_line="$(printf '%s\n' "$activation_script" | grep -nF 'Boring profile cleanup: unloading org.nixos.yabai' | cut -d: -f1)"
if (( cleanup_line <= user_launchd_line )); then
    echo "Boring cleanup must run after nix-darwin removes stale user LaunchAgents." >&2
    exit 1
fi

if [[ "$(cd "$repo_root" && nix eval --json '.#darwinConfigurations.olisikh-mini-boring.config.services.yabai.enable')" != false ]]; then
    echo "Boring profile must disable yabai." >&2
    exit 1
fi

printf '%s\n' "boring profile activation tests passed"
