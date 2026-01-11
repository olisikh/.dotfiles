#!/bin/bash

LOG_FILE="/tmp/sketchybar_pomodoro.log"
echo "$(date): Script started with args: $*" >> "$LOG_FILE"

SOUNDS_PATH="/System/Library/PrivateFrameworks/ScreenReader.framework/Versions/A/Resources/Sounds/"
COUNTDOWN_PID_FILE="/tmp/sketchybar_timer_pid"
DEFAULT_DURATION=1500 # 25 minutes

__start() {
	local name="$1"
	local duration="$2"
	echo "$(date): Starting countdown for $name, duration $duration" >> "$LOG_FILE"

	(
		local time_left="$duration"

		while [ "$time_left" -gt 0 ]; do
			local minutes=$((time_left / 60))
			local seconds=$((time_left % 60))
			sketchybar --set "$name" label="$(printf "%02d:%02d" "$minutes" "$seconds")"
			sleep 1
			time_left=$((time_left - 1))
		done

		afplay "$SOUNDS_PATH/GuideSuccess.aiff"
		sketchybar --set "$name" label="Done"
	) &
	printf "%s\n" "$!" >"$COUNTDOWN_PID_FILE"
}

__stop() {
	echo "$(date): Stopping countdown" >> "$LOG_FILE"
	if [ -f "$COUNTDOWN_PID_FILE" ]; then
		if IFS= read -r PID <"$COUNTDOWN_PID_FILE"; then
			if ps -p "$PID" >/dev/null 2>&1; then
				kill -- "$PID"
			fi
		fi
		rm -f "$COUNTDOWN_PID_FILE"
	fi
}

start_countdown() {
	echo "$(date): Starting countdown with name $1, duration $2" >> "$LOG_FILE"
	__stop
	__start "$1" "$2"
	afplay "$SOUNDS_PATH/TrackingOn.aiff"
}

stop_countdown() {
	echo "$(date): Stopping countdown" >> "$LOG_FILE"
	__stop
	afplay "$SOUNDS_PATH/TrackingOff.aiff"
	sketchybar --set "$NAME" label="No Timer"
}

# If script is run directly with a duration argument (e.g. ./pomodoro.sh 300)
if [[ "$#" -eq 1 && "$1" =~ ^[0-9]+$ ]]; then
	start_countdown "$(echo "$NAME" | awk -F'.' '{print $1}')" "$1"
	exit 0
fi

# Handle SketchyBar mouse events
if [ "$SENDER" = "mouse.clicked" ]; then
	echo "$(date): Mouse clicked, button $BUTTON, sender $SENDER, name $NAME" >> "$LOG_FILE"
	case "$BUTTON" in
	"left")
		start_countdown "$NAME" "$DEFAULT_DURATION"
		;;
	"right")
		stop_countdown
		;;
	esac
fi

case "$SENDER" in
"mouse.entered")
	echo "$(date): Mouse entered" >> "$LOG_FILE"
	sketchybar --set "$NAME" popup.drawing=on
	;;
"mouse.exited" | "mouse.exited.global")
	echo "$(date): Mouse exited" >> "$LOG_FILE"
	sketchybar --set "$NAME" popup.drawing=off
	;;
esac
