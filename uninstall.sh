#!/usr/bin/env zsh

# unstow folders
echo "unstowing .dotfiles"

for folder in *
do
    [ ! -d $folder ] && continue

    echo "unstowing $folder"
    stow -D $folder
done
