#!/usr/bin/env bash

LOG_FILE="/tmp/spotify_debug.log"

case "$SENDER" in
	"mouse.entered")
		sketchybar --set spotify popup.drawing=on
		;;
	"mouse.exited"|"mouse.exited.global")
		sketchybar --set spotify popup.drawing=off
		;;
	*)
		# Check if Spotify is running
		if ! pgrep -x "Spotify" > /dev/null; then
			echo "$(date): Spotify not running" >> "$LOG_FILE"
			sketchybar --set "$NAME" drawing=off
			exit 0
		fi

		# Get Spotify state using osascript
		STATE=$(osascript -e 'tell application "Spotify" to player state' 2>/dev/null)
		TITLE=$(osascript -e 'tell application "Spotify" to name of current track' 2>/dev/null)
		ARTIST=$(osascript -e 'tell application "Spotify" to artist of current track' 2>/dev/null)

		echo "$(date): Polled STATE: $STATE, TITLE: $TITLE, ARTIST: $ARTIST" >> "$LOG_FILE"

		if [ "$STATE" = "playing" ] || [ "$STATE" = "paused" ]; then
			MEDIA="$TITLE - $ARTIST"
			echo "$(date): Setting label to: $MEDIA" >> "$LOG_FILE"
			sketchybar --set "$NAME" label="$MEDIA" drawing=on
			# Update play button icon
			if [ "$STATE" = "playing" ]; then
				sketchybar --set spotify.play icon=󰏤
			else
				sketchybar --set spotify.play icon=󰐊
			fi
		else
			echo "$(date): Hiding widget (STATE: $STATE)" >> "$LOG_FILE"
			sketchybar --set "$NAME" drawing=off
		fi
		;;
esac
