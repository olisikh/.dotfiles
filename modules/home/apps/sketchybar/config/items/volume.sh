#!/usr/bin/env bash

COLOR="$GREEN"

sketchybar \
	--add item sound right \
	--set sound \
	icon.color="$COLOR" \
	label.color="$COLOR" \
	label.padding_right=10 \
	label.width=45 \
	background.height=26 \
	background.corner_radius="$CORNER_RADIUS" \
	background.padding_right=5 \
	background.border_width="$BORDER_WIDTH" \
	background.color="$BAR_COLOR" \
	background.drawing=on \
	script="$PLUGIN_DIR/sound.sh" \
	--subscribe sound volume_change
