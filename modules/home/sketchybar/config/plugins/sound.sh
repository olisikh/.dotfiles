#!/usr/bin/env bash

VOLUME=$(osascript -e "output volume of (get volume settings)")
MUTED=$(osascript -e "output muted of (get volume settings)")

if [ "$MUTED" != "false" ]; then
	ICON="󰖁"
	VOLUME=0
elif [ "$VOLUME" -le 33 ]; then
	ICON=" "
else
	ICON=" "
fi
sketchybar -m \
	--set "$NAME" \
	icon="$ICON" \
	label="$VOLUME%"
