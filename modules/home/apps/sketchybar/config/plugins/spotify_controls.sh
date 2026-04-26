#!/usr/bin/env bash

source "$HOME/.config/sketchybar/variables.sh"

case "$SENDER" in
"mouse.clicked")
	case "$NAME" in
	"spotify.prev")
		osascript -e 'tell application "Spotify" to previous track'
		sleep 0.2
		"$PLUGIN_DIR/spotify.sh"
		;;
	"spotify.play")
		osascript -e 'tell application "Spotify" to playpause'
		sleep 0.5
		"$PLUGIN_DIR/spotify.sh"
		;;
	"spotify.next")
		osascript -e 'tell application "Spotify" to next track'
		sleep 0.2
		"$PLUGIN_DIR/spotify.sh"
		;;
	esac
	;;
esac
