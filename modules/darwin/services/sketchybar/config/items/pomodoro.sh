#!/bin/bash

source "$HOME/.config/sketchybar/variables.sh"

COLOR="$RED"

sketchybar --add item timer right \
            --set timer label="No Timer" \
            icon=🍅 \
            icon.color="$COLOR" \
            icon.padding_left=10 \
            label.padding_right=10 \
            label.color="$COLOR" \
            background.height=26 \
            background.corner_radius="$CORNER_RADIUS" \
            background.padding_right=5 \
            background.border_width="$BORDER_WIDTH" \
            background.border_color="$COLOR" \
            background.color="$BAR_COLOR" \
            background.drawing=on \
            script="$PLUGIN_DIR/pomodoro.sh" \
            popup.background.corner_radius="$POPUP_CORNER_RADIUS" \
            popup.background.color="$POPUP_BACKGROUND_COLOR" \
            popup.background.border_width="$POPUP_BORDER_WIDTH" \
            popup.background.border_color="$POPUP_BORDER_COLOR" \
            --subscribe timer mouse.clicked mouse.entered mouse.exited mouse.exited.global

for timer in "5" "10" "25" "50"; do
            sketchybar --add item "timer.${timer}" popup.timer \
                        --set "timer.${timer}" label="${timer} Minutes" \
                        padding_left=16 \
                        padding_right=16 \
                        click_script="$HOME/.config/sketchybar/plugins/pomodoro.sh $((timer * 60)); sketchybar -m --set timer popup.drawing=off"
done
