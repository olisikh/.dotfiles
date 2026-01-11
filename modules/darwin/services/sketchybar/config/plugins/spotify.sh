#!/usr/bin/env bash

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
		sketchybar --set "$NAME" drawing=off
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
		sketchybar --set "$NAME" label="$MEDIA" drawing=on

		# Update play button icon
		if [ "$STATE" = "playing" ]; then
			sketchybar --set spotify.play icon="󰏤 "
		else
			sketchybar --set spotify.play icon="󰐊 "
		fi
	else
		echo "$(date): Hiding widget (STATE: $STATE)" >>"$LOG_FILE"
		sketchybar --set "$NAME" drawing=off
	fi
	# Set album art
	if [ -n "$ARTWORK_URL" ]; then
		ARTWORK_FILE="/tmp/spotify_artwork.jpg"
		echo "$(date): Downloading $ARTWORK_URL to $ARTWORK_FILE" >>"$LOG_FILE"
		curl -s "$ARTWORK_URL" -o "$ARTWORK_FILE"
		echo "$(date): Curl exit code: $?" >>"$LOG_FILE"

		if [ -f "$ARTWORK_FILE" ] && [ -s "$ARTWORK_FILE" ]; then
			echo "$(date): Setting image to $ARTWORK_FILE" >>"$LOG_FILE"
			sketchybar --set spotify.artwork image="$ARTWORK_FILE" drawing=on
		else
			echo "$(date): File not found or empty" >>"$LOG_FILE"
			sketchybar --set spotify.artwork drawing=off
		fi
	else
		echo "$(date): No artwork URL" >>"$LOG_FILE"
		sketchybar --set spotify.artwork drawing=off
	fi
	;;
esac
