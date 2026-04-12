#!/usr/bin/env bash

COLOR="$WHITE"

sketchybar \
	--add item front_app left \
	--set front_app script="$PLUGIN_DIR/front_app.sh" \
	icon.color="$COLOR" \
	icon.font="$APP_ICON_FONT:13.0" \
	icon.padding_left=10 \
	label.color="$COLOR" \
	label.padding_right=10 \
	background.padding_right=10 \
	background.height=26 \
	background.border_width="$BORDER_WIDTH" \
	background.border_color="$COLOR" \
	background.corner_radius="$CORNER_RADIUS" \
	background.color="$BAR_COLOR" \
	associated_display=active \
	--subscribe front_app front_app_switched
