#!/usr/bin/env bash

# The mini has no window manager and no workspace items to update.
if ! command -v aerospace >/dev/null 2>&1 && ! command -v yabai >/dev/null 2>&1; then
	exit 0
fi

source "$HOME/.config/sketchybar/variables.sh"
source "$HOME/.config/sketchybar/helpers/icon_map.sh"

if command -v aerospace >/dev/null 2>&1; then
	ACTIVE_SPACE=$(aerospace list-workspaces --focused 2>/dev/null)
	WINDOWS=$(aerospace list-windows --all --format '%{workspace}|%{app-name}' 2>/dev/null)

	for sid in {1..10}; do
		ICON_STRING=""
		ICON_COUNT=0
		while IFS='|' read -r workspace app_name; do
			[ "$workspace" = "$sid" ] || continue
			[ -n "$app_name" ] || continue
			__icon_map "$app_name"
			ICON_STRING="${ICON_STRING}${icon_result}"
			ICON_COUNT=$((ICON_COUNT + 1))
			[ "$ICON_COUNT" -ge "${MAX_SPACE_ICONS:-4}" ] && break
		done <<<"$WINDOWS"

		if [ "$sid" = "$ACTIVE_SPACE" ]; then
			sketchybar --set "space.$sid" icon.color="$RED" label.color="$WHITE" label="$ICON_STRING"
		else
			sketchybar --set "space.$sid" icon.color="$COMMENT" label.color="$COMMENT" label="$ICON_STRING"
		fi
	done
	exit 0
fi

# Query yabai once for spaces and windows
SPACES_JSON=$(yabai -m query --spaces 2>/dev/null)
WINDOWS_JSON=$(yabai -m query --windows 2>/dev/null)

# Find active space index
ACTIVE_SPACE=$(echo "$SPACES_JSON" | jq -r '.[] | select(.["has-focus"] == true) | .index')

# For each space 1-10
for sid in {1..10}; do
	# Yabai repeats sticky/all-spaces windows in every space's `windows` list.
	# Assign those windows to the active space instead of displaying them everywhere.
	SPACE_WINDOW_IDS=$(echo "$WINDOWS_JSON" | jq -r \
		--arg sid "$sid" \
		--arg active_space "$ACTIVE_SPACE" \
		'.[] | select((.["is-sticky"] == true and $sid == $active_space) or (.["is-sticky"] != true and (.space | tostring) == $sid)) | .id' \
		2>/dev/null)

	# Build icon string (max 4 icons)
	ICON_STRING=""
	ICON_COUNT=0
	if [ -n "$SPACE_WINDOW_IDS" ]; then
		while IFS= read -r wid; do
			[ -z "$wid" ] && continue
			APP_NAME=$(echo "$WINDOWS_JSON" | jq -r ".[] | select(.id == $wid) | .app" 2>/dev/null)
			[ -z "$APP_NAME" ] || [ "$APP_NAME" = "null" ] && continue
			__icon_map "$APP_NAME"
			ICON_STRING="${ICON_STRING}${icon_result}"
			ICON_COUNT=$((ICON_COUNT + 1))
			[ "$ICON_COUNT" -ge "${MAX_SPACE_ICONS:-4}" ] && break
		done <<<"$SPACE_WINDOW_IDS"
	fi

	# Set colors based on active state
	# Note: sketchybar space items auto-enable highlight for the active space,
	# so highlight_color must be set to match color.
	if [ "$sid" = "$ACTIVE_SPACE" ]; then
		sketchybar --set "space.$sid" \
			icon.color="$RED" \
			icon.highlight_color="$RED" \
			label.color="$WHITE" \
			label="$ICON_STRING"
	else
		sketchybar --set "space.$sid" \
			icon.color="$COMMENT" \
			icon.highlight_color="$COMMENT" \
			label.color="$COMMENT" \
			label="$ICON_STRING"
	fi
done
