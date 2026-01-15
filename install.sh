#!/usr/bin/env zsh

set -e

# verify nix installation
if ! command -v nix-env &> /dev/null
then
    echo "Nix is missing, install Determinate Nix before proceeding."
fi

# NOTE: if the LocalHostName value is wrong:
# sudo scutil --set LocalHostName <hostname>
# sudo scutil --set HostName <hostname>
HOSTNAME=$(/usr/sbin/scutil --get LocalHostName)

# download the internet and install flake
sudo nix build .#darwinConfigurations.${HOSTNAME}.system --show-trace --print-build-logs -v

# activate nix-darwin and home-manager
sudo ./result/sw/bin/darwin-rebuild switch --flake .

