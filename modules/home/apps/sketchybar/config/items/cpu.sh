#!/usr/bin/env bash

COLOR="$YELLOW"

sketchybar --add item cpu right \
	--set cpu \
	update_freq=3 \
	icon.color="$COLOR" \
	label.color="$COLOR" \
	label.padding_right=10 \
	label.width=55 \
	background.height=26 \
	background.corner_radius="$CORNER_RADIUS" \
	background.border_width="$BORDER_WIDTH" \
	background.drawing=on \
	script="$PLUGIN_DIR/cpu.sh"
