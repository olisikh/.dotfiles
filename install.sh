#!/usr/bin/env zsh

# verify nix installation
if ! command -v nix-env &> /dev/null
then
    echo "nix-env is not installed, exiting..."
    exit
fi

# copy nix.conf
mkdir -p ~/.config/nix
cp -fr nix.conf ~/.config/nix/nix.conf

# install home manager
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A install

# overwrite default home.nix
cp -fr home.nix ~/.config/home-manager/home.nix

# install packages
home-manager switch

