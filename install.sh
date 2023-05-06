#!/usr/bin/env zsh

# 1. install nix
echo "installing nix"
if [ ! command -v nix-env &> /dev/null ]; then
    curl -L https://nixos.org/nix/install | sh
else
    echo "nix already installed"
fi

# 2. install nix packages
echo "installing nix packages"
nix-env -iA \
    nixpkgs.zsh \
    nixpkgs.git \
    nixpkgs.oh-my-zsh \
    nixpkgs.starship \
    nixpkgs.stow \
    nixpkgs.fd \
    nixpkgs.fzf \
    nixpkgs.zoxide \
    nixpkgs.ripgrep \
    nixpkgs.lua \
    nixpkgs.neovim \
    nixpkgs.tmux \
    nixpkgs.rustup \
    nixpkgs.thefuck \
    nixpkgs.docker \
    nixpkgs.docker-machine \
    nixpkgs.minikube \
    nixpkgs.kubernetes-helm \
    nixpkgs.awscli2 \
    nixpkgs.yarn \
    nixpkgs.nerdfonts \
    nixpkgs.rectangle

# 3. stow .dotfiles
echo "stowing .dotfiles"

for folder in *
do
    [ ! -d $folder ] && continue
    echo "stowing $folder"
    stow -R $folder
    stow $folder
done

# 4. install tmux tpm (plugin manager)
[ ! -d ~/.tmux/plugins/tpm ] && git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

echo "done."

