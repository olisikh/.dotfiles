#!/usr/bin/env bash

LAST_FILE="/tmp/sketchybar_wifi_last"
NOW=$(date +%s)

# Get active network interface
IFACE=$(route -n get default 2>/dev/null | awk '/interface:/{print $2}')

# SF Symbols wifi icons
#   U+100647 = 􀙇 wifi connected
#   U+100648 = 􀙈 wifi disconnected
WIFI_ON=$(python3 -c 'print(chr(0x100647))')
WIFI_OFF=$(python3 -c 'print(chr(0x100648))')

# No default route = offline
if [ -z "$IFACE" ]; then
	sketchybar --set wifi icon="$WIFI_OFF" \
		background.height=26 \
		background.corner_radius="$CORNER_RADIUS" \
		background.border_width="$BORDER_WIDTH" \
		background.border_color="$COLOR" \
		background.color="$BAR_COLOR" \
		background.drawing=on \
		--set wifi.up drawing=off \
		--set wifi.down drawing=off \
		--set wifi_bracket background.drawing=off
	rm -f "$LAST_FILE"
	exit 0
fi

# Read byte counters from netstat
NET_DATA=$(netstat -ibn | awk -v iface="$IFACE" '$1 == iface {print $7, $10; exit}')
IBYTES=$(echo "$NET_DATA" | awk '{print $1}')
OBYTES=$(echo "$NET_DATA" | awk '{print $2}')

# If interface has no counter data
if [ -z "$IBYTES" ] || [ -z "$OBYTES" ]; then
	sketchybar --set wifi icon="$WIFI_OFF" \
		background.height=26 \
		background.corner_radius="$CORNER_RADIUS" \
		background.border_width="$BORDER_WIDTH" \
		background.border_color="$COLOR" \
		background.color="$BAR_COLOR" \
		background.drawing=on \
		--set wifi.up drawing=off \
		--set wifi.down drawing=off \
		--set wifi_bracket background.drawing=off
	rm -f "$LAST_FILE"
	exit 0
fi

# Format rate helper
format_rate() {
	local rate=$1
	if [ "$rate" -lt 1024 ]; then
		echo "${rate}B/s"
	elif [ "$rate" -lt 1048576 ]; then
		awk -v r="$rate" 'BEGIN {printf "%.1fKB/s", r/1024}'
	else
		awk -v r="$rate" 'BEGIN {printf "%.1fMB/s", r/1048576}'
	fi
}

# First run or no previous data
if [ ! -f "$LAST_FILE" ]; then
	echo "$NOW $IBYTES $OBYTES $IFACE" > "$LAST_FILE"
	sketchybar --set wifi icon="$WIFI_ON" background.drawing=off \
		--set wifi.up drawing=on label="↑ ???" label.drawing=on \
		--set wifi.down drawing=on label="↓ ???" label.drawing=on \
		--set wifi_bracket background.drawing=on
	exit 0
fi

read -r LAST_TIME LAST_IBYTES LAST_OBYTES LAST_IFACE < "$LAST_FILE"

# Reset if interface changed
if [ "$LAST_IFACE" != "$IFACE" ]; then
	echo "$NOW $IBYTES $OBYTES $IFACE" > "$LAST_FILE"
	sketchybar --set wifi icon="$WIFI_ON" background.drawing=off \
		--set wifi.up drawing=on label="↑ ???" label.drawing=on \
		--set wifi.down drawing=on label="↓ ???" label.drawing=on \
		--set wifi_bracket background.drawing=on
	exit 0
fi

ELAPSED=$((NOW - LAST_TIME))
[ "$ELAPSED" -le 0 ] && ELAPSED=1

DELTA_IBYTES=$((IBYTES - LAST_IBYTES))
DELTA_OBYTES=$((OBYTES - LAST_OBYTES))

# Counter reset or wrap
if [ "$DELTA_IBYTES" -lt 0 ] || [ "$DELTA_OBYTES" -lt 0 ]; then
	echo "$NOW $IBYTES $OBYTES $IFACE" > "$LAST_FILE"
	sketchybar --set wifi icon="$WIFI_ON" background.drawing=off \
		--set wifi.up drawing=on label="↑ ???" label.drawing=on \
		--set wifi.down drawing=on label="↓ ???" label.drawing=on \
		--set wifi_bracket background.drawing=on
	exit 0
fi

UP_RATE=$((DELTA_OBYTES / ELAPSED))
DOWN_RATE=$((DELTA_IBYTES / ELAPSED))

UP_FMT=$(format_rate "$UP_RATE")
DOWN_FMT=$(format_rate "$DOWN_RATE")

sketchybar --set wifi icon="$WIFI_ON" background.drawing=off \
	--set wifi.up drawing=on label="↑ ${UP_FMT}" label.drawing=on \
	--set wifi.down drawing=on label="↓ ${DOWN_FMT}" label.drawing=on \
	--set wifi_bracket background.drawing=on

# Store current sample
echo "$NOW $IBYTES $OBYTES $IFACE" > "$LAST_FILE"
