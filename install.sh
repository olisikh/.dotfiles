#!/usr/bin/env zsh

# verify nix installation
if ! command -v nix-env &> /dev/null
then
    echo "Nix is missing, install Determinate Nix before proceeding."
fi

HOSTNAME=$(/usr/sbin/scutil --get LocalHostName)

# download the internet and install flake
sudo nix build .#darwinConfigurations.${HOSTNAME}.system --show-trace --print-build-logs -vvv && \
  ./result/sw/bin/darwin-rebuild switch --flake .

