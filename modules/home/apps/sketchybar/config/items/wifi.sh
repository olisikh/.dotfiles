#!/usr/bin/env bash

COLOR="$BLUE"
RATE_WIDTH=70

# Download (bottom line, rightmost in group — placed first for right-side ordering)
sketchybar --add item wifi.down right \
	--set wifi.down \
	icon.drawing=off \
	label.font="$FONT:Bold:10.0" \
	label.color="$COLOR" \
	label.width="$RATE_WIDTH" \
	label.align=left \
	label.padding_left=0 \
	label.padding_right=0 \
	padding_left=0 \
	padding_right=0 \
	y_offset=-6 \
	background.drawing=off

# Upload (top line, overlaps wifi.down horizontally via negative padding_right)
sketchybar --add item wifi.up right \
	--set wifi.up \
	icon.drawing=off \
	label.font="$FONT:Bold:10.0" \
	label.color="$COLOR" \
	label.width="$RATE_WIDTH" \
	label.align=left \
	label.padding_left=0 \
	label.padding_right=0 \
	padding_left=0 \
	padding_right=-$RATE_WIDTH \
	y_offset=6 \
	background.drawing=off

# Wifi icon (leftmost in group)
sketchybar --add item wifi right \
	--set wifi \
	update_freq=2 \
	icon="󰤨 " \
	icon.color="$COLOR" \
	icon.padding_right=5 \
	label.drawing=off \
	padding_left=0 \
	padding_right=0 \
	background.drawing=off \
	script="$PLUGIN_DIR/wifi.sh"

# Shared background bracket
sketchybar --add bracket wifi_bracket wifi wifi.up wifi.down \
	--set wifi_bracket \
	background.height=26 \
	background.corner_radius="$CORNER_RADIUS" \
	background.padding_right=5 \
	background.border_width="$BORDER_WIDTH" \
	background.color="$BAR_COLOR" \
	background.drawing=on
