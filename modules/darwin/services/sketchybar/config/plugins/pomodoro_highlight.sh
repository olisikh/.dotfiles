#!/bin/bash

source "$HOME/.config/sketchybar/variables.sh"

case "$SENDER" in
"mouse.entered")
    sketchybar --set "$NAME" background.color="$HOVER_COLOR"
    ;;
"mouse.exited")
    sketchybar --set "$NAME" background.color="$POPUP_BACKGROUND_COLOR"
    ;;
esac

