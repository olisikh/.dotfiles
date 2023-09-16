#!/bin/bash

stow zsh git tmux

DOT=$(pwd)

mkdir -p $HOME/starship $HOME/.config/alacritty

ln -s $DOT/alacritty/alacritty.yml $HOME/.config/alacritty/alacritty.yml
ln -s $DOT/starship.toml $HOME/starship/starship.toml
ln -s $DOT/nvim $HOME/.config/nvim

