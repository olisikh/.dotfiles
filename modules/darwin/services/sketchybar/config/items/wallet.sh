#!/usr/bin/env bash

COLOR="$GREEN"

sketchybar --add item wallet right \
	--set wallet \
	icon="💰" \
	icon.color="$COLOR" \
	icon.padding_left=10 \
	background.color="$BAR_COLOR" \
	background.height=26 \
	background.corner_radius="$CORNER_RADIUS" \
	background.border_width="$BORDER_WIDTH" \
	background.border_color="$COLOR" \
	background.padding_right=-5 \
	background.drawing=on \
	label.padding_right=10 \
	label.max_chars=30 \
	updates=on \
	update_freq=300 \
	environment.OPENROUTER_API_KEY="$OPENROUTER_API_KEY" \
	environment.OPENCODE_API_KEY="$OPENCODE_API_KEY" \
	script="$PLUGIN_DIR/wallet.sh"
