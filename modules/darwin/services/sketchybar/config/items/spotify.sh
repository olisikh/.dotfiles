#!/usr/bin/env bash

COLOR="$GREEN"

sketchybar --add item spotify left \
	--set spotify \
	scroll_texts=on \
	scroll_duration=99 \
	icon="󰎆 " \
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
	label.max_chars=43 \
	associated_display=active \
	updates=on \
	update_freq=5 \
	script="$PLUGIN_DIR/spotify.sh" \
	popup.horizontal=on \
	popup.align=center \
	popup.height=80 \
	--subscribe spotify mouse.entered mouse.exited mouse.exited.global

sketchybar --add item spotify.artwork popup.spotify \
	--set spotify.artwork \
	drawing=off \
	background.image.drawing=off \
	background.drawing=on \
	background.color=0x00000000 \
	background.image.scale=0.15 \
	updates=on \
	width=100

# Add popup controls
sketchybar --add item spotify.prev popup.spotify \
	--set spotify.prev icon="󰒮 " \
	icon.color="$COLOR" \
	icon.width=40 \
	icon.height=40 \
	icon.font.size=20 \
	label.drawing=off \
	padding_left=10 \
	padding_right=10 \
	click_script="osascript -e 'tell application \"Spotify\" to previous track' && $PLUGIN_DIR/spotify.sh"

sketchybar --add item spotify.play popup.spotify \
	--set spotify.play icon="󰐊 " \
	icon.color="$COLOR" \
	icon.width=40 \
	icon.height=40 \
	icon.font.size=20 \
	label.drawing=off \
	padding_left=10 \
	padding_right=10 \
	click_script="osascript -e 'tell application \"Spotify\" to playpause' && $PLUGIN_DIR/spotify.sh"

sketchybar --add item spotify.next popup.spotify \
	--set spotify.next icon="󰒭 " \
	icon.color="$COLOR" \
	icon.width=40 \
	icon.height=40 \
	icon.font.size=20 \
	label.drawing=off \
	padding_left=10 \
	padding_right=10 \
	click_script="osascript -e 'tell application \"Spotify\" to next track' && $PLUGIN_DIR/spotify.sh"
