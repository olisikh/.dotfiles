#!/usr/bin/env bash

SPACE_ICONS=("1" "2" "3" "4" "5" "6" "7" "8" "9" "10")

sketchybar --add item spacer.1 left \
	--set spacer.1 background.drawing=off \
	label.drawing=off \
	icon.drawing=off \
	width=10

for i in {0..9}; do
	sid=$((i + 1))
	sketchybar --add space space.$sid left \
		--set space.$sid associated_space=$sid \
		icon="${SPACE_ICONS[$i]}" \
		icon.font="$FONT:Bold:13.0" \
		icon.color="$COMMENT" \
		icon.padding_left=10 \
		icon.padding_right=4 \
		label.font="$APP_ICON_FONT:Regular:11.0" \
		label.color="$COMMENT" \
		label.padding_left=4 \
		label.padding_right=10 \
		label.y_offset=0 \
		icon.y_offset=0 \
		background.padding_left=-5 \
		background.padding_right=-5 \
		click_script="yabai -m space --focus $sid"
done

sketchybar --add item spacer.2 left \
	--set spacer.2 background.drawing=off \
	label.drawing=off \
	icon.drawing=off \
	width=5

sketchybar --add bracket spaces '/space\.[0-9]+/' \
	--set spaces background.border_width="$BORDER_WIDTH" \
	background.corner_radius="$CORNER_RADIUS" \
	background.color="$BAR_COLOR" \
		background.height=28 \
		background.drawing=on

sketchybar --add item separator left \
	--set separator icon= \
	icon.font="$FONT:Regular:16.0" \
	background.padding_left=10 \
	background.padding_right=10 \
	label.drawing=off \
	associated_display=active \
	icon.color="$YELLOW"

# Hidden controller item that updates all spaces on events
sketchybar --add item space_controller left \
	--set space_controller drawing=off \
	updates=on \
	script="$PLUGIN_DIR/space.sh" \
	--subscribe space_controller space_change front_app_switched space_update

# Yabai signals to trigger updates on window changes
yabai -m signal --add label=sketchybar_space event=window_created \
	action="sketchybar --trigger space_update" 2>/dev/null
yabai -m signal --add label=sketchybar_space event=window_destroyed \
	action="sketchybar --trigger space_update" 2>/dev/null
yabai -m signal --add label=sketchybar_space event=window_minimized \
	action="sketchybar --trigger space_update" 2>/dev/null
yabai -m signal --add label=sketchybar_space event=window_deminimized \
	action="sketchybar --trigger space_update" 2>/dev/null
