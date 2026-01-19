#!/bin/bash

source "$HOME/.config/sketchybar/variables.sh"

LOG_FILE="/tmp/sketchybar_pomodoro.log"
echo "$(date): Script started with args: $*" >>"$LOG_FILE"

SOUNDS_PATH="/System/Library/PrivateFrameworks/ScreenReader.framework/Versions/A/Resources/Sounds/"
COUNTDOWN_PID_FILE="/tmp/sketchybar_timer_pid"
COOLDOWN_FILE="/tmp/sketchybar_cooldown"
DEFAULT_DURATION=1500 # 25 minutes

TIMER_OWNER_PID_FILE="/tmp/sketchybar_timer_owner_pid"

cleanup_timer_state() {
	rm -f "$COUNTDOWN_PID_FILE" "$TIMER_OWNER_PID_FILE"
}

cancel_running_timer() {
	local existing_pid owner_pid
	if [ -f "$COUNTDOWN_PID_FILE" ]; then
		if IFS= read -r existing_pid <"$COUNTDOWN_PID_FILE"; then
			if [ -n "$existing_pid" ] && ps -p "$existing_pid" >/dev/null 2>&1; then
				echo "$(date): Cancelling existing timer (PID $existing_pid)" >>"$LOG_FILE"
				kill -- "$existing_pid" >/dev/null 2>&1 || true
				wait "$existing_pid" >/dev/null 2>&1 || true
			fi
		fi
	fi

	if [ -f "$TIMER_OWNER_PID_FILE" ]; then
		if IFS= read -r owner_pid <"$TIMER_OWNER_PID_FILE"; then
			if [ -n "$owner_pid" ] && [ "$owner_pid" != "$$" ] && ps -p "$owner_pid" >/dev/null 2>&1; then
				echo "$(date): Cancelling owner script (PID $owner_pid)" >>"$LOG_FILE"
				kill -- "$owner_pid" >/dev/null 2>&1 || true
			fi
		fi
	fi

	cleanup_timer_state
}

COLOR=$POMODORO_COLOR
COLOR_COOLDOWN=$POMODORO_COOLDOWN_COLOR

play_sound() {
	local sound="$1"
	local repeat_count="${2:-1}"
	local delay="${3:-1}"

	for ((i = 1; i <= repeat_count; i++)); do
		afplay "$sound"
		if [ "$i" -lt "$repeat_count" ]; then
			sleep "$delay"
		fi
	done
}

timer_start() {
	local name="$1"
	local duration="$2"
	local cooldown="$3"
	local timer_pid
	cancel_running_timer
	echo "$(date): Starting countdown for $name, duration $duration, cooldown $cooldown" >>"$LOG_FILE"
	echo "$cooldown" >"$COOLDOWN_FILE"

	(
		local time_left="$duration"

		while [ "$time_left" -gt 0 ]; do
			local minutes=$((time_left / 60))
			local seconds=$((time_left % 60))
			sketchybar --set "timer" label="$(printf "%02d:%02d" "$minutes" "$seconds")" label.drawing=on
			sleep 1
			time_left=$((time_left - 1))
		done

		# Start cooldown
		play_sound "$SOUNDS_PATH/GuideSuccess.aiff" 3 .2 &
		sketchybar --set "timer" icon=🥒 label.color="$COLOR_COOLDOWN"

		if [ "$cooldown" -gt 0 ]; then
			time_left="$cooldown"
			while [ "$time_left" -gt 0 ]; do
				minutes=$((time_left / 60))
				seconds=$((time_left % 60))
				sketchybar --set "timer" label="$(printf "%02d:%02d" "$minutes" "$seconds")" label.drawing=on
				sleep 1
				time_left=$((time_left - 1))
			done
		fi

		play_sound "$SOUNDS_PATH/GuideSuccess.aiff" 3 .2 &
		sketchybar --set "timer" icon=🍅 label.color="$COLOR" label.drawing=off
		rm -f "$COOLDOWN_FILE"
		cleanup_timer_state
	) &
	timer_pid="$!"
	printf "%s\n" "$timer_pid" >"$COUNTDOWN_PID_FILE"
	printf "%s\n" "$$" >"$TIMER_OWNER_PID_FILE"
}

timer_stop() {
	echo "$(date): Stopping countdown" >>"$LOG_FILE"
	cancel_running_timer
	sketchybar --set "timer" icon=🍅 label.color="$COLOR" label.drawing=off
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
	echo "$(date): Starting countdown with name $name, duration $duration, cooldown $cooldown" >>"$LOG_FILE"
	timer_stop
	timer_start "$name" "$duration" "$cooldown"
	play_sound "$SOUNDS_PATH/TrackingOn.aiff" &
}

stop_countdown() {
	timer_stop
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
	echo "$(date): Mouse clicked, button $BUTTON, sender $SENDER, name $NAME" >>"$LOG_FILE"
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
	sketchybar --set "$NAME" background.color="$POMODORO_HIGHLIGHT_COLOR"
	sketchybar --set "timer" popup.drawing=on
	;;
"mouse.exited" | "mouse.exited.global")
	sketchybar --set "$NAME" background.color="$BAR_COLOR"
	sketchybar --set "timer" popup.drawing=off
	;;
esac
