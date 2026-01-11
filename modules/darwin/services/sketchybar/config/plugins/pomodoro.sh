#!/bin/bash

source "$HOME/.config/sketchybar/variables.sh"

LOG_FILE="/tmp/sketchybar_pomodoro.log"
echo "$(date): Script started with args: $*" >> "$LOG_FILE"

SOUNDS_PATH="/System/Library/PrivateFrameworks/ScreenReader.framework/Versions/A/Resources/Sounds/"
COUNTDOWN_PID_FILE="/tmp/sketchybar_timer_pid"
COOLDOWN_FILE="/tmp/sketchybar_cooldown"
DEFAULT_DURATION=1500 # 25 minutes

COLOR=$POMODORO_COLOR
COLOR_COOLDOWN=$POMODORO_COOLDOWN_COLOR

timer_start() {
	local name="$1"
	local duration="$2"
	local cooldown="$3"
	echo "$(date): Starting countdown for $name, duration $duration, cooldown $cooldown" >> "$LOG_FILE"
	echo "$cooldown" > "$COOLDOWN_FILE"

	(
		local time_left="$duration"

		while [ "$time_left" -gt 0 ]; do
			local minutes=$((time_left / 60))
			local seconds=$((time_left % 60))
			sketchybar --set "timer" label="$(printf "%02d:%02d" "$minutes" "$seconds")"
			sleep 1
			time_left=$((time_left - 1))
		done

		# Start cooldown
		sketchybar --set "timer" icon=🥒 label.color="$COLOR_COOLDOWN"
		if [ "$cooldown" -gt 0 ]; then
			time_left="$cooldown"
			while [ "$time_left" -gt 0 ]; do
				minutes=$((time_left / 60))
				seconds=$((time_left % 60))
				sketchybar --set "timer" label="$(printf "%02d:%02d" "$minutes" "$seconds")"
				sleep 1
				time_left=$((time_left - 1))
			done
		fi

		afplay "$SOUNDS_PATH/GuideSuccess.aiff"
		sketchybar --set "timer" icon=🍅 label.color="$COLOR" label="Pomodoro"
		rm -f "$COOLDOWN_FILE"
	) &
	printf "%s\n" "$!" >"$COUNTDOWN_PID_FILE"
}

timer_stop() {
	echo "$(date): Stopping countdown" >> "$LOG_FILE"
	if [ -f "$COUNTDOWN_PID_FILE" ]; then
		if IFS= read -r PID <"$COUNTDOWN_PID_FILE"; then
			if ps -p "$PID" >/dev/null 2>&1; then
				kill -- "$PID"
			fi
		fi
		rm -f "$COUNTDOWN_PID_FILE"
	fi
	sketchybar --set "timer" icon=🍅 label.color="$COLOR" label="Pomodoro"
	rm -f "$COOLDOWN_FILE"
}

start_countdown() {
	local name="$1"
	local duration="$2"
	local cooldown=0
	case "$duration" in
		300) cooldown=300 ;;  # 5 min -> 5 min
		900) cooldown=300 ;;  # 15 min -> 5 min
		1500) cooldown=300 ;; # 25 min -> 5 min
		3000) cooldown=600 ;; # 50 min -> 10 min
		*) cooldown=0 ;;
	esac
	echo "$(date): Starting countdown with name $name, duration $duration, cooldown $cooldown" >> "$LOG_FILE"
	timer_stop
	timer_start "$name" "$duration" "$cooldown"
	afplay "$SOUNDS_PATH/TrackingOn.aiff"
}

stop_countdown() {
	echo "$(date): Stopping countdown" >> "$LOG_FILE"
	if [ -f "$COUNTDOWN_PID_FILE" ]; then
		if IFS= read -r PID <"$COUNTDOWN_PID_FILE"; then
			if ps -p "$PID" >/dev/null 2>&1; then
				kill -- "$PID"
			fi
		fi
		rm -f "$COUNTDOWN_PID_FILE"
	fi
	sketchybar --set "timer" icon=🍅 label.color="$COLOR" label="Pomodoro"
	rm -f "$COOLDOWN_FILE"
}

# If script is run directly with a duration argument (e.g. ./pomodoro.sh 300)
if [[ "$#" -eq 1 && "$1" = "cancel" ]]; then
	stop_countdown
	exit 0
elif [[ "$#" -eq 1 && "$1" =~ ^[0-9]+$ ]]; then
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
	echo "$(date): Mouse entered $NAME" >> "$LOG_FILE"
	sketchybar --set "$NAME" label.color="$COLOR" background.color="$POMODORO_HIGHLIGHT_COLOR"
	sketchybar --set "timer" popup.drawing=on
	;;
"mouse.exited" | "mouse.exited.global")
	echo "$(date): Mouse exited $NAME" >> "$LOG_FILE"
	sketchybar --set "$NAME" label.color="$COLOR" background.color="$BAR_COLOR"
	sketchybar --set "timer" popup.drawing=off
	;;
esac
