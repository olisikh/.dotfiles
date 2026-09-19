#!/usr/bin/env zsh

set -e

usage() {
    cat <<EOF
Usage: $(basename "$0") [-p|--profile PROFILE]

Install and switch this nix-darwin configuration.

Profiles:
  default (default)  Use the configuration named after this Mac's LocalHostName.
  boring             Available only for olisikh-mini.
EOF
}

profile="default"
while (( $# > 0 )); do
    case "$1" in
    -p | --profile)
        if (( $# < 2 )) || [[ -z "$2" || "$2" == -* ]]; then
            echo "Error: --profile requires a profile name." >&2
            exit 1
        fi
        profile="$2"
        shift 2
        ;;
    --profile=*)
        profile="${1#*=}"
        if [[ -z "$profile" ]]; then
            echo "Error: --profile requires a profile name." >&2
            exit 1
        fi
        shift
        ;;
    -h | --help)
        usage
        exit 0
        ;;
    *)
        echo "Error: unknown argument '$1'." >&2
        usage >&2
        exit 1
        ;;
    esac
done

if [[ ! "$profile" =~ ^[[:alnum:]_-]+$ ]]; then
    echo "Error: invalid profile name '$profile'." >&2
    exit 1
fi

# verify nix installation
if ! command -v nix-env &> /dev/null
then
    echo "Nix is missing, install Determinate Nix before proceeding."
fi

# NOTE: if the LocalHostName value is wrong:
# sudo scutil --set LocalHostName <hostname>
# sudo scutil --set HostName <hostname>
scutil_bin="${SCUTIL_BIN:-/usr/sbin/scutil}"
hostname=$("$scutil_bin" --get LocalHostName)
flake_system="$hostname"
if [[ "$profile" != "default" ]]; then
    flake_system="${hostname}-${profile}"
fi

entrypoint="systems/aarch64-darwin/${flake_system}/default.nix"
if [[ ! -f "$entrypoint" ]]; then
    echo "Error: profile '$profile' is not available for system '$hostname'." >&2
    echo "Expected Snowfall entrypoint: $entrypoint" >&2
    exit 1
fi

install_user="${SUDO_USER:-${USER:-$(id -un)}}"
echo "==> Profile: $profile"
echo "==> System reference: .#darwinConfigurations.${flake_system}"
echo "==> Home reference: .#homeConfigurations.\"${install_user}@${flake_system}\""

# Download the dependencies and build the selected flake configuration.
sudo nix build ".#darwinConfigurations.${flake_system}.system" --show-trace --print-build-logs -v

# Activate nix-darwin and Home Manager from the configuration just built.
sudo ./result/sw/bin/darwin-rebuild switch --flake ".#${flake_system}"

