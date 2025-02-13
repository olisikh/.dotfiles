#!/usr/bin/env zsh

# verify nix installation
if ! command -v nix-env &> /dev/null
then
    echo "Nix is missing, will install Determinate Nix bundle, follow the guide"
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
else
    echo "Nix is installed, good."
fi

# copy nix.conf
mkdir -p ~/.config/nix
cp -fr ~/.dotfiles/nix.conf ~/.config/nix/nix.conf

# download the internet and install flake
HOSTNAME=$(scutil --get ComputerName)

nix build .#darwinConfigurations.olisikh.system --impure --show-trace && \
  ./result/sw/bin/darwin-rebuild switch --flake . --impure

