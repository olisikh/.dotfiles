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
		osascript -e 'tell application "Spotify" to previous track'
		sleep 0.2
		"$PLUGIN_DIR/spotify.sh"
		;;
	"spotify.play")
		# Optimistic update
		CURRENT_ICON=$(sketchybar --query spotify.play | jq -r '.icon.value')
		if [ "$CURRENT_ICON" = "󰐊 " ]; then
			sketchybar --set spotify.play icon="󰏤 "
		else
			sketchybar --set spotify.play icon="󰐊 "
		fi
		
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
