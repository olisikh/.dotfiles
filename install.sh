#!/usr/bin/env zsh

# verify nix installation
if ! command -v nix-env &> /dev/null
then
    echo "[ERROR]: nix is not installed, please install nix before proceeding"
    exit
fi

# copy nix.conf
mkdir -p ~/.config/nix
cp -fr ~/.dotfiles/nix.conf ~/.config/nix/nix.conf

# download the internet and install flake
nix run .#homeConfigurations.home.activationPackage --impure --show-trace

