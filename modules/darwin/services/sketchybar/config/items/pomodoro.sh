#!/bin/bash

source "$HOME/.config/sketchybar/variables.sh"

COLOR=$POMODORO_COLOR

sketchybar --remove timer
for timer in "5" "15" "25" "50" "cancel"; do
    sketchybar --remove "timer.${timer}"
done

sketchybar --add item timer right \
    --set timer label="Pomodoro" \
    icon=🍅 \
    icon.color="$COLOR" \
    icon.padding_left=10 \
    label.padding_right=10 \
    label.color="$COLOR" \
    background.height=26 \
    background.corner_radius="$CORNER_RADIUS" \
    background.padding_right=5 \
    background.border_width="$BORDER_WIDTH" \
    background.border_color="$RED" \
    background.color="$BAR_COLOR" \
    background.drawing=on \
    script="$PLUGIN_DIR/pomodoro.sh" \
    popup.background.corner_radius="$POPUP_CORNER_RADIUS" \
    popup.background.color="$POPUP_BACKGROUND_COLOR" \
    popup.background.border_width="$POPUP_BORDER_WIDTH" \
    popup.background.border_color="$POPUP_BORDER_COLOR" \
    --subscribe timer mouse.clicked mouse.entered mouse.exited mouse.exited.global

for timer in "5" "15" "25" "50" "cancel"; do
    if [ "$timer" = "cancel" ]; then
        duration="cancel"
        label="Cancel Timer"
    else
        duration=$((timer * 60))
        label="${timer} Minutes"
    fi

    NAME="timer.${timer}"

    sketchybar --add item "$NAME" popup.timer \
        --set "$NAME" label="$label" \
        icon.drawing=off \
        width=110 \
        align=center \
        padding_left=5 \
        padding_right=5 \
        background.color="$POPUP_BACKGROUND_COLOR" \
        background.drawing=on \
        background.height=30 \
        background.corner_radius=5 \
        click_script="$HOME/.config/sketchybar/plugins/pomodoro.sh $duration; 
    
    sketchybar -m --set timer popup.drawing=off" \
        script="$PLUGIN_DIR/pomodoro_highlight.sh" \
        --subscribe "$NAME" mouse.entered mouse.exited
done
