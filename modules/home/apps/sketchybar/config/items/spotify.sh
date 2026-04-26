#!/usr/bin/env bash

source "$HOME/.config/sketchybar/variables.sh"

COLOR="$GREEN"

# Spotify icon (leftmost)
sketchybar --add item spotify.icon left \
	--set spotify.icon \
	icon=":spotify:" \
	icon.font="$APP_ICON_FONT:15.0" \
	icon.color="$COLOR" \
	icon.padding_left=6 \
	icon.padding_right=2 \
	label.drawing=off \
	background.drawing=off \
	click_script="open -a Spotify"

# Previous track
sketchybar --add item spotify.prev left \
	--set spotify.prev \
	icon="󰒮" \
	icon.color="$COLOR" \
	icon.font="$FONT:Bold:16.0" \
	label.drawing=off \
	padding_left=1 \
	padding_right=1 \
	background.drawing=off \
	script="$PLUGIN_DIR/spotify_controls.sh" \
	--subscribe spotify.prev mouse.clicked

# Play/Pause
sketchybar --add item spotify.play left \
	--set spotify.play \
	icon="󰐊" \
	icon.color="$COLOR" \
	icon.font="$FONT:Bold:16.0" \
	label.drawing=off \
	padding_left=1 \
	padding_right=1 \
	background.drawing=off \
	script="$PLUGIN_DIR/spotify_controls.sh" \
	--subscribe spotify.play mouse.clicked

# Next track
sketchybar --add item spotify.next left \
	--set spotify.next \
	icon="󰒭" \
	icon.color="$COLOR" \
	icon.font="$FONT:Bold:16.0" \
	label.drawing=off \
	padding_left=1 \
	padding_right=1 \
	background.drawing=off \
	script="$PLUGIN_DIR/spotify_controls.sh" \
	--subscribe spotify.next mouse.clicked

# Song name + artist
sketchybar --add item spotify left \
	--set spotify \
	label.color="$WHITE" \
	label.font="$FONT:Bold:13.0" \
	label.padding_right=10 \
	label.max_chars=43 \
	icon.drawing=off \
	background.drawing=off \
	associated_display=active \
	updates=on \
	update_freq=5 \
	script="$PLUGIN_DIR/spotify.sh"

# Shared background bracket
sketchybar --add bracket spotify_group spotify.icon spotify.prev spotify.play spotify.next spotify \
	--set spotify_group \
	background.color="$BAR_COLOR" \
	background.height=26 \
	background.corner_radius="$CORNER_RADIUS" \
	background.border_width="$BORDER_WIDTH" \
	background.drawing=on
