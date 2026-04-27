#!/usr/bin/env bash

source "$HOME/.config/sketchybar/variables.sh"
source "$HOME/.config/sketchybar/helpers/icon_map.sh"

# Query yabai once for spaces and windows
SPACES_JSON=$(yabai -m query --spaces 2>/dev/null)
WINDOWS_JSON=$(yabai -m query --windows 2>/dev/null)

# Find active space index
ACTIVE_SPACE=$(echo "$SPACES_JSON" | jq -r '.[] | select(.["has-focus"] == true) | .index')

# For each space 1-10
for sid in {1..10}; do
	# Get window IDs for this space
	SPACE_WINDOW_IDS=$(echo "$SPACES_JSON" | jq -r ".[] | select(.index == $sid) | .windows[]?" 2>/dev/null)

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
		done <<< "$SPACE_WINDOW_IDS"
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
