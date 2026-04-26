#!/usr/bin/env bash

COLOR="$MAGENTA"

sketchybar --add item calendar right \
	--set calendar update_freq=15 \
	icon.color="$COLOR" \
	label.color="$COLOR" \
	label.padding_right="$PADDINGS" \
	background.height=26 \
	background.corner_radius="$CORNER_RADIUS" \
	background.border_width="$BORDER_WIDTH" \
	background.color="$BAR_COLOR" \
	background.drawing=on \
	script="$PLUGIN_DIR/calendar.sh"
