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
"mouse.clicked")
	case "$NAME" in
	"spotify.prev")
		osascript -e 'tell application "Spotify" to previous track' && "$PLUGIN_DIR/spotify.sh"
		;;
	"spotify.play")
		osascript -e 'tell application "Spotify" to playpause' && "$PLUGIN_DIR/spotify.sh"
		;;
	"spotify.next")
		osascript -e 'tell application "Spotify" to next track' && "$PLUGIN_DIR/spotify.sh"
		;;
	esac
	;;
esac
