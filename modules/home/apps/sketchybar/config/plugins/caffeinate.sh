#!/bin/bash

source "$HOME/.config/sketchybar/variables.sh"

# SF Symbols icons:
#   U+100E18 = 􀸘 cup.and.saucer (empty cup - caffeinate OFF)
#   U+100E19 = 􀸙 cup.and.saucer.fill (filled cup - caffeinate ON)

ICON_OFF=$(python3 -c 'print(chr(0x100E18))')
ICON_ON=$(python3 -c 'print(chr(0x100E19))')

CAFFINATE_ID=$(pmset -g assertions | grep "caffeinate" | awk '{print $2}' | cut -d '(' -f1 | head -n 1)

# It is an initial load
if [ -z "$BUTTON" ]; then
  if [ -z "$CAFFINATE_ID" ]; then
    sketchybar --set "$NAME" icon="$ICON_OFF"
  else
    sketchybar --set "$NAME" icon="$ICON_ON"
  fi
  exit 0
fi

# It is a mouse click
if [ -z "$CAFFINATE_ID" ]; then
  caffeinate -id &
  sketchybar --set "$NAME" icon="$ICON_ON"
else
  kill -9 "$CAFFINATE_ID"
  sketchybar --set "$NAME" icon="$ICON_OFF"
fi
