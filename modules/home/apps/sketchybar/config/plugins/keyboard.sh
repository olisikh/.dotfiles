#!/usr/bin/env bash

LOG_FILE="${HOME}/.cache/sketchybar/keyboard.log"
mkdir -p "$(dirname "$LOG_FILE")"

read_layout_from_defaults() {
	defaults read com.apple.HIToolbox AppleSelectedInputSources 2>/dev/null |
		awk -F"= " '/KeyboardLayout Name/ {
		layout=$2
		gsub(/"|;/, "", layout)
		gsub(/^[ \t]+|[ \t]+$/, "", layout)
		print layout
		exit
	}'
}

short_layout_label() {
	local layout="$1"
	local lowered="${layout,,}"

	case "$lowered" in
	*polish*)
		echo "PL"
		;;
	*ukrainian*)
		echo "UA"
		;;
	*british* | *united\ kingdom* | *uk-*)
		echo "UK"
		;;
	*u.s.* | *american* | *us-* | *united\ states*)
		echo "US"
		;;
	*german*)
		echo "DE"
		;;
	*french*)
		echo "FR"
		;;
	*spanish*)
		echo "ES"
		;;
	*)
		local cleaned
		cleaned=$(echo "$layout" | tr -cd '[:alnum:] ')
		if [ -n "$cleaned" ]; then
			local initials
			initials=$(echo "$cleaned" | awk '{for(i=1;i<=NF;i++) printf "%s", toupper(substr($i,1,1))}')
			echo "${initials:0:2}"
		else
			echo "${layout:0:2}"
		fi
		;;
	esac
}

LAYOUT=$(read_layout_from_defaults)
if [ -z "$LAYOUT" ]; then
	LAYOUT=$(osascript -e 'tell application "System Events" to get name of current input source' 2>/dev/null | tr -d '\r\n')
fi

if [ -z "$LAYOUT" ]; then
	echo "$(date -u +'%Y-%m-%dT%H:%M:%SZ') keyboard: no layout detected" >>"$LOG_FILE"
	exit 0
fi

SHORT_LABEL=$(short_layout_label "$LAYOUT")
echo "$(date -u +'%Y-%m-%dT%H:%M:%SZ') keyboard: layout '$(printf '%s' "$LAYOUT")' -> '$SHORT_LABEL'" >>"$LOG_FILE"

sketchybar -m \
	--set "$NAME" \
	label="$SHORT_LABEL"
