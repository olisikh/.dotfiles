#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

activation_script="$(
    cd "$repo_root"
    nix eval --raw '.#darwinConfigurations.olisikh-mini-boring.config.system.activationScripts.script.text'
)"
user_home="$(cd "$repo_root" && nix eval --raw '.#darwinConfigurations.olisikh-mini-boring.config.olisikh.core.user.home')"

for expected in \
    'label="org.nixos.yabai"' \
    'label="org.nixos.skhd"' \
    'label="org.nixos.aerospace"' \
    'launchctl bootout "gui/$uid/$label"' \
    'launchctl unload "$agent"' \
    'rm -f "$agent"'; do
    if [[ "$activation_script" != *"$expected"* ]]; then
        echo "Expected boring activation script to contain: $expected" >&2
        exit 1
    fi
done

user_launchd_line="$(printf '%s\n' "$activation_script" | grep -nF 'for f in /run/current-system/user/Library/LaunchAgents/*; do' | cut -d: -f1)"
for service in yabai skhd aerospace; do
    cleanup_line="$(printf '%s\n' "$activation_script" | grep -nF "label=\"org.nixos.$service\"" | cut -d: -f1)"
    if (( cleanup_line <= user_launchd_line )); then
        echo "$service cleanup must run after nix-darwin removes stale user LaunchAgents." >&2
        exit 1
    fi

    cleanup_block="$(printf '%s\n' "$activation_script" | sed -n "${cleanup_line},$((cleanup_line + 9))p")"
    expected_agent="agent=\"${user_home}/Library/LaunchAgents/\$label.plist\""
    for expected in "$expected_agent" 'launchctl bootout "gui/$uid/$label"' 'launchctl unload "$agent"' 'rm -f "$agent"'; do
        if [[ "$cleanup_block" != *"$expected"* ]]; then
            echo "Expected $service cleanup to contain: $expected" >&2
            exit 1
        fi
    done

    if [[ "$(cd "$repo_root" && nix eval --json ".#darwinConfigurations.olisikh-mini-boring.config.services.$service.enable")" != false ]]; then
        echo "Boring profile must disable $service." >&2
        exit 1
    fi
done

printf '%s\n' "boring profile activation tests passed"
