#!/usr/bin/env bash

sketchybar --add event keyboard_layout_change com.apple.Carbon.TISNotifySelectedKeyboardInputSourceChanged

COLOR="$WHITE"

sketchybar --add item keyboard right \
	--set keyboard \
	icon=" " \
	icon.color="$COLOR" \
	label.color="$COLOR" \
	label.width=30 \
	background.height=26 \
	background.corner_radius="$CORNER_RADIUS" \
	background.border_width="$BORDER_WIDTH" \
	background.drawing=on \
	script="$PLUGIN_DIR/keyboard.sh" \
	--subscribe keyboard keyboard_layout_change
