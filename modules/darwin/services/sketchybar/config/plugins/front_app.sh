#!/usr/bin/env bash

LOG_FILE="${HOME}/.cache/sketchybar/front_app.log"

source "$HOME/.config/sketchybar/helpers/icon_map.sh"

echo "$(date): Script started with args: $INFO" >>"$LOG_FILE"

case "$SENDER" in
"front_app_switched")
	__icon_map "$INFO"
	echo "$(date): The icon is: $icon_result" >>"$LOG_FILE"

	sketchybar --set "$NAME" label="$INFO" icon="$icon_result"
	;;
esac
