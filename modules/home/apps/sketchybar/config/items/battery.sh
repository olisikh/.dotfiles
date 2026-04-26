#!/usr/bin/env bash

COLOR="$CYAN"

# Only create the battery item on systems that expose an internal battery.
has_battery() {
	if ioreg -r -c AppleSmartBattery -d 1 2>/dev/null | grep -q '"BatteryInstalled" = Yes'; then
		return 0
	fi

	pmset -g batt 2>/dev/null | grep -q "InternalBattery"
}

if has_battery; then
	sketchybar --add item battery right \
		--set battery \
		update_freq=60 \
		icon.color="$COLOR" \
		label.padding_right=10 \
		label.color="$COLOR" \
		label.width=45 \
		background.height=26 \
		background.corner_radius="$CORNER_RADIUS" \
		background.padding_right=5 \
		background.border_width="$BORDER_WIDTH" \
		background.color="$BAR_COLOR" \
		background.drawing=on \
		script="$PLUGIN_DIR/power.sh" \
		--subscribe battery power_source_change
fi

