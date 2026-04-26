#!/usr/bin/env bash

COLOR="$ORANGE"

sketchybar --add item memory right \
	--set memory \
	update_freq=3 \
	icon.color="$COLOR" \
	label.color="$COLOR" \
	label.padding_right="$PADDINGS" \
	label.width=50 \
	background.height=26 \
	background.corner_radius="$CORNER_RADIUS" \
	background.padding_right=5 \
	background.border_width="$BORDER_WIDTH" \
	background.drawing=on \
	script="$PLUGIN_DIR/memory.sh"
