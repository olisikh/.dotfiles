#!/usr/bin/env zsh

source init.sh

pushd $DOT_FILES
for folder in $(echo $STOW_FOLDERS | sed "s/,/ /g")
do
    echo "Removing $folder"
    stow -D $folder
done
popd
