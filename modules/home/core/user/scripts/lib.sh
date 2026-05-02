#!/usr/bin/env bash

NIX_DOTFILES_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

resolve_dotfiles_root() {
    if [[ -n "${NIX_DOTFILES_ROOT:-}" ]]; then
        printf '%s\n' "$NIX_DOTFILES_ROOT"
        return
    fi

    local repo_root
    repo_root="$(cd "$NIX_DOTFILES_SCRIPT_DIR/.." && pwd -P)"
    if [[ -f "$repo_root/flake.nix" ]]; then
        printf '%s\n' "$repo_root"
        return
    fi

    printf '%s\n' "$HOME/.dotfiles"
}

NIX_DOTFILES_ROOT="$(resolve_dotfiles_root)"

check_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Error: $1 not found. Please install it or enable the corresponding module."
        exit 1
    fi
}
