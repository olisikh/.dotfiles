#!/bin/bash

COLOR="$BROWN"

sketchybar --add item caffeinate right \
  --set caffeinate script="$PLUGIN_DIR/caffeinate.sh" \
  click_script="$PLUGIN_DIR/caffeinate.sh" \
  icon.color="$COLOR" \
  icon.padding_left=12 \
  background.height=26 \
  background.corner_radius="$CORNER_RADIUS" \
  background.border_width="$BORDER_WIDTH" \
  background.border_color="$COLOR" \
  background.color="$BAR_COLOR" \
  background.border_color="$COLOR" \
  background.drawing=on
