#!/usr/bin/env bash

CPU_COLOR="$YELLOW"
MEMORY_COLOR="$ORANGE"
STAT_WIDTH=58

# Memory (bottom line, rightmost in group — placed first for right-side ordering)
sketchybar --add item cpu_memory_memory right \
	--set cpu_memory_memory \
	icon.drawing=off \
	label.font="$FONT:Bold:10.0" \
	label.color="$MEMORY_COLOR" \
	label.width="$STAT_WIDTH" \
	label.align=left \
	label.padding_left="$PADDINGS" \
	label.padding_right=0 \
	padding_left=0 \
	padding_right=0 \
	y_offset=-6 \
	background.drawing=off

# CPU (top line, overlaps cpu_memory_memory horizontally via negative padding_right)
sketchybar --add item cpu_memory_cpu right \
	--set cpu_memory_cpu \
	icon.drawing=off \
	label.font="$FONT:Bold:10.0" \
	label.color="$CPU_COLOR" \
	label.width="$STAT_WIDTH" \
	label.align=left \
	label.padding_left="$PADDINGS" \
	label.padding_right=0 \
	padding_left=0 \
	padding_right=-$STAT_WIDTH \
	y_offset=6 \
	background.drawing=off

# CPU/memory icon (leftmost in group)
sketchybar --add item cpu_memory right \
	--set cpu_memory \
	update_freq=3 \
	icon.drawing=off \
	label.drawing=off \
	padding_left=0 \
	padding_right=0 \
	background.drawing=off \
	script="$PLUGIN_DIR/cpu_memory.sh"

# Shared background bracket
sketchybar --add bracket cpu_memory_bracket cpu_memory cpu_memory_cpu cpu_memory_memory \
	--set cpu_memory_bracket \
	background.height=26 \
	background.corner_radius="$CORNER_RADIUS" \
	background.padding_right=5 \
	background.border_width="$BORDER_WIDTH" \
	background.color="$BAR_COLOR" \
	background.drawing=on
