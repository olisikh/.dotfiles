#!/usr/bin/env bash

source "$HOME/.config/sketchybar/variables.sh"

LOG_FILE="/tmp/spotify_debug.log"

echo "$(date): Script started with NAME=$NAME, SENDER=$SENDER" >>"$LOG_FILE"

# Check if Spotify is running
if ! pgrep -x "Spotify" >/dev/null; then
	echo "$(date): Spotify not running" >>"$LOG_FILE"
	sketchybar --set spotify drawing=off \
		--set spotify.icon drawing=off \
		--set spotify.prev drawing=off \
		--set spotify.play drawing=off \
		--set spotify.next drawing=off
	exit 0
fi

# Get Spotify state using osascript
STATE=$(osascript -e 'tell application "Spotify" to player state' 2>/dev/null)
TITLE=$(osascript -e 'tell application "Spotify" to name of current track' 2>/dev/null)
ARTIST=$(osascript -e 'tell application "Spotify" to artist of current track' 2>/dev/null)

echo "$(date): Polled STATE: $STATE, TITLE: $TITLE, ARTIST: $ARTIST" >>"$LOG_FILE"

if [ "$STATE" = "playing" ] || [ "$STATE" = "paused" ]; then
	MEDIA="$TITLE - $ARTIST"
	echo "$(date): Setting label to: $MEDIA" >>"$LOG_FILE"
	sketchybar --set spotify label="$MEDIA" drawing=on \
		--set spotify.icon drawing=on \
		--set spotify.prev drawing=on \
		--set spotify.play drawing=on \
		--set spotify.next drawing=on

	# Update play button icon
	if [ "$STATE" = "playing" ]; then
		sketchybar --set spotify.play icon="󰏤"
	else
		sketchybar --set spotify.play icon="󰐊"
	fi
else
	echo "$(date): Hiding widget (STATE: $STATE)" >>"$LOG_FILE"
	sketchybar --set spotify drawing=off \
		--set spotify.icon drawing=off \
		--set spotify.prev drawing=off \
		--set spotify.play drawing=off \
		--set spotify.next drawing=off
fi
