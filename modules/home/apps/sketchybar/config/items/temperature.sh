#!/usr/bin/env bash

if ! command -v macmon >/dev/null 2>&1; then
	exit 0
fi

TEMP_COLOR="$YELLOW"
STAT_WIDTH=58

sketchybar --add item temperature right \
	--set temperature \
	update_freq=5 \
	icon.drawing=off \
	label.drawing=on \
	label.font="$FONT:Bold:13.0" \
	label.color="$TEMP_COLOR" \
	label.width="$STAT_WIDTH" \
	label.align=left \
	label.padding_left="$PADDINGS" \
	label.padding_right="$PADDINGS" \
	padding_left=0 \
	padding_right="$PADDINGS" \
	background.drawing=off \
	script="$PLUGIN_DIR/temperature.sh"

# Shared background bracket
sketchybar --add bracket temperature_bracket temperature \
	--set temperature_bracket \
	background.height=26 \
	background.corner_radius="$CORNER_RADIUS" \
	background.padding_right="$PADDINGS" \
	background.border_width="$BORDER_WIDTH" \
	background.color="$BAR_COLOR" \
	background.drawing=on
