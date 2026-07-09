#!/bin/bash

COLOR="$BROWN"

sketchybar --add item caffeinate right \
  --set caffeinate \
  script="$PLUGIN_DIR/caffeinate.sh" \
  click_script="$PLUGIN_DIR/caffeinate.sh" \
  icon.color="$COLOR" \
  icon.font="$SF_ICON_FONT:$FONT_SIZE" \
  icon.padding_right="$PADDINGS" \
  label.drawing=off \
  background.height=26 \
  background.corner_radius="$CORNER_RADIUS" \
  background.border_width="$BORDER_WIDTH" \
  background.color="$BAR_COLOR" \
  background.drawing=on
