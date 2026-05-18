#!/usr/bin/env bash

COLOR="$CYAN"
CODEXBAR_ICON_FONT="CodexBar Provider Icons:Regular:15.0"
CODEXBAR_LABEL_WIDTH=70
CODEXBAR_ICON_MAP="$HOME/.config/sketchybar/helpers/codexbar_icon_map.sh"
CODEXBAR_PROVIDERS=(
	codex
	claude
	cursor
	opencode
	opencodego
	alibaba-coding-plan
	factory
	gemini
	antigravity
	copilot
	zai
	minimax
	kimi
	kilo
	kiro
	vertexai
	augment
	jetbrains
	kimik2
	amp
	ollama
	synthetic
	warp
	openrouter
	windsurf
	perplexity
	abacusai
	mistral
	deepseek
	codebuff
)

if [[ -f "$CODEXBAR_ICON_MAP" ]]; then
	source "$CODEXBAR_ICON_MAP"
fi

provider_icon_key() {
	case "$1" in
	abacusai) printf '%s\n' "abacus" ;;
	alibaba-coding-plan) printf '%s\n' "alibaba" ;;
	kimik2) printf '%s\n' "kimi" ;;
	*) printf '%s\n' "$1" ;;
	esac
}

provider_icon() {
	local icon_result=""

	if declare -F __codexbar_icon_map >/dev/null; then
		__codexbar_icon_map "$(provider_icon_key "$1")"
	fi

	printf '%s\n' "$icon_result"
}

# Bottom label (line 2) — rightmost, placed first for right-side ordering
sketchybar --add item codexbar.l2 right \
	--set codexbar.l2 \
	drawing=off \
	icon.drawing=off \
	label.font="$FONT:Bold:10.0" \
	label.color="$COLOR" \
	label.width="$CODEXBAR_LABEL_WIDTH" \
	label.align=left \
	label.padding_left=0 \
	label.padding_right=0 \
	padding_left=0 \
	padding_right=0 \
	y_offset=-6 \
	background.drawing=off \
	script="$PLUGIN_DIR/codexbar.sh" \
	--subscribe codexbar.l2 mouse.entered mouse.exited.global

# Top label (line 1) — overlaps l2 horizontally via negative padding_right
sketchybar --add item codexbar.l1 right \
	--set codexbar.l1 \
	drawing=off \
	icon.drawing=off \
	label.font="$FONT:Bold:10.0" \
	label.color="$COLOR" \
	label.width="$CODEXBAR_LABEL_WIDTH" \
	label.align=left \
	label.padding_left=0 \
	label.padding_right=0 \
	padding_left=0 \
	padding_right=-$CODEXBAR_LABEL_WIDTH \
	y_offset=6 \
	background.drawing=off \
	script="$PLUGIN_DIR/codexbar.sh" \
	--subscribe codexbar.l1 mouse.entered mouse.exited.global

# Icon item — leftmost in the group
sketchybar --add item codexbar right \
	--set codexbar \
	update_freq=300 \
	icon="$(provider_icon codex)" \
	icon.font="$CODEXBAR_ICON_FONT" \
	icon.color="$COLOR" \
	icon.padding_left=8 \
	icon.padding_right=6 \
	label.padding_right="$PADDINGS" \
	label.drawing=off \
	background.drawing=off \
	script="$PLUGIN_DIR/codexbar.sh" \
	click_script="$PLUGIN_DIR/codexbar.sh" \
	popup.background.corner_radius="$POPUP_CORNER_RADIUS" \
	popup.background.color="$POPUP_BACKGROUND_COLOR" \
	popup.background.border_width="$POPUP_BORDER_WIDTH" \
	popup.background.border_color="$POPUP_BORDER_COLOR" \
	popup.blur_radius=20 \
	popup.align=center \
	--subscribe codexbar mouse.entered mouse.exited.global

# Shared background bracket
sketchybar --add bracket codexbar_bracket codexbar codexbar.l1 codexbar.l2 \
	--set codexbar_bracket \
	background.height=26 \
	background.corner_radius="$CORNER_RADIUS" \
	background.padding_right=5 \
	background.border_width="$BORDER_WIDTH" \
	background.color="$BAR_COLOR" \
	background.drawing=on

for provider in "${CODEXBAR_PROVIDERS[@]}"; do
	item="codexbar.${provider}"

	sketchybar --add item "$item" popup.codexbar \
		--set "$item" \
		drawing=off \
		icon="$(provider_icon "$provider")" \
		icon.font="$CODEXBAR_ICON_FONT" \
		icon.color="$LABEL_COLOR" \
		icon.padding_left=10 \
		icon.padding_right=8 \
		label.color="$LABEL_COLOR" \
		label.padding_left=0 \
		label.padding_right=12 \
		label.width=250 \
		label.align=left \
		label.font="$FONT:Bold:12.0" \
		background.color="$POPUP_BACKGROUND_COLOR" \
		background.height=30 \
		background.corner_radius=5 \
		background.drawing=on \
		click_script="$PLUGIN_DIR/codexbar.sh select $provider"
done
