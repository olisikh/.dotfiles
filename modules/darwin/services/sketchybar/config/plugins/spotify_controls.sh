#!/usr/bin/env bash

HOVER_COLOR=0xff3b4261
TRANSPARENT=0x00000000

case "$SENDER" in
"mouse.entered")
	sketchybar --set "$NAME" background.color="$HOVER_COLOR"
	;;
"mouse.exited")
	sketchybar --set "$NAME" background.color="$TRANSPARENT"
	;;
esac
