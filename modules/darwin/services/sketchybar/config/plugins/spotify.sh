#!/usr/bin/env bash

source "$HOME/.config/sketchybar/variables.sh" # Loads all defined colors

LOG_FILE="/tmp/spotify_debug.log"
echo "$(date): Script started with NAME=$NAME" >>"$LOG_FILE"

case "$SENDER" in
"mouse.entered")
	sketchybar --set spotify popup.drawing=on
	;;
"mouse.exited" | "mouse.exited.global")
	sketchybar --set spotify popup.drawing=off
	;;
*)
	# Check if Spotify is running
	if ! pgrep -x "Spotify" >/dev/null; then
		echo "$(date): Spotify not running" >>"$LOG_FILE"
		sketchybar --set spotify drawing=off
		exit 0
	fi

	# Get Spotify state using osascript
	STATE=$(osascript -e 'tell application "Spotify" to player state' 2>/dev/null)
	TITLE=$(osascript -e 'tell application "Spotify" to name of current track' 2>/dev/null)
	ARTIST=$(osascript -e 'tell application "Spotify" to artist of current track' 2>/dev/null)
	ARTWORK_URL=$(osascript -e 'tell application "Spotify" to artwork url of current track' 2>/dev/null)

	echo "$(date): Polled STATE: $STATE, TITLE: $TITLE, ARTIST: $ARTIST" >>"$LOG_FILE"

	if [ "$STATE" = "playing" ] || [ "$STATE" = "paused" ]; then
		MEDIA="$TITLE - $ARTIST"
		echo "$(date): Setting label to: $MEDIA" >>"$LOG_FILE"
		sketchybar --set spotify label="$MEDIA" drawing=on

		# Update play button icon
		if [ "$STATE" = "playing" ]; then
			sketchybar --set spotify.play icon="󰏤 "
		else
			sketchybar --set spotify.play icon="󰐊 "
		fi
	else
		echo "$(date): Hiding widget (STATE: $STATE)" >>"$LOG_FILE"
		sketchybar --set spotify drawing=off background.image.drawing=off
	fi
	# Set album art
	if [ -n "$ARTWORK_URL" ]; then
		ARTWORK_FILE="/tmp/spotify_artwork.jpg"
		
		LAST_URL_FILE="/tmp/spotify_last_url"
		LAST_URL=$(cat "$LAST_URL_FILE" 2>/dev/null)

		if [ "$ARTWORK_URL" != "$LAST_URL" ] || [ ! -f "$ARTWORK_FILE" ]; then
			echo "$(date): Downloading new artwork..." >>"$LOG_FILE"
			curl -s "$ARTWORK_URL" -o "$ARTWORK_FILE"
			echo "$ARTWORK_URL" > "$LAST_URL_FILE"
		fi

		if [ -f "$ARTWORK_FILE" ] && [ -s "$ARTWORK_FILE" ]; then
			sketchybar --set spotify.artwork background.image="$ARTWORK_FILE" drawing=on background.image.drawing=on
		else
			sketchybar --set spotify.artwork drawing=off background.image.drawing=off
		fi
	else
		sketchybar --set spotify.artwork drawing=off background.image.drawing=off
	fi
	;;
esac
