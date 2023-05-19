#!/usr/bin/env zsh

# verify nix installation
if ! command -v nix-env &> /dev/null
then
    echo "nix-env is not installed, exiting..."
    exit
fi

declare -A users
users=(["O.Lisikh"]="work" ["olisikh"]="olisikh")
user=$users[$USER]

if [ -z $user ]; then
    echo "User $USER is not defined in users table."
    return -1
fi

# copy nix.conf
mkdir -p ~/.config/nix
cp -fr ~/.dotfiles/nix.conf ~/.config/nix/nix.conf

# download the internet and install flake
nix run .#homeConfigurations.$user.activationPackage --impure --show-trace

