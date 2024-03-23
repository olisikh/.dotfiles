#!/usr/bin/env zsh

# verify nix installation
if ! command -v nix-env &> /dev/null
then
    echo "nix-env is not installed, exiting..."
    exit
fi

# copy nix.conf
mkdir -p ~/.config/nix
cp -fr ~/.dotfiles/nix.conf ~/.config/nix/nix.conf

# download the internet and install flake
nix run .#homeConfigurations.olisikh.activationPackage --impure --show-trace

