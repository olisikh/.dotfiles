#!/bin/bash

COLOR="$BROWN"
CAFFINATE_ID=$(pmset -g assertions | grep "caffeinate" | awk '{print $2}' | cut -d '(' -f1 | head -n 1)

# It is an initial load
if [ -z "$BUTTON" ]; then
  if [ -z "$CAFFINATE_ID" ]; then
    sketchybar --set "$NAME" icon=" "
  else
    sketchybar --set "$NAME" icon=" "
  fi
  exit 0
fi

# It is a mouse click
if [ -z "$CAFFINATE_ID" ]; then
  caffeinate -id &
  sketchybar --set "$NAME" icon=" "
else
  kill -9 "$CAFFINATE_ID"
  sketchybar --set "$NAME" icon=" "
fi
