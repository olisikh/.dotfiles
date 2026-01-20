#!/usr/bin/env bash

sketchybar --add event keyboard_layout_change com.apple.Carbon.TISNotifySelectedKeyboardInputSourceChanged

COLOR="$WHITE"

sketchybar --add item keyboard right \
	--set keyboard \
	update_freq=15 \
	icon=" " \
	icon.color="$COLOR" \
	icon.padding_left=10 \
	label.color="$COLOR" \
	label.padding_right=10 \
	label.width=30 \
	background.height=26 \
	background.corner_radius="$CORNER_RADIUS" \
	background.padding_right=5 \
	background.border_width="$BORDER_WIDTH" \
	background.border_color="$COLOR" \
	background.color="$BAR_COLOR" \
	background.drawing=on \
	script="$PLUGIN_DIR/keyboard.sh" \
	--subscribe keyboard_layout_change
