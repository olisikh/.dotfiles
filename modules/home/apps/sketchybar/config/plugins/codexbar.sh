#!/usr/bin/env bash

source "$HOME/.config/sketchybar/variables.sh"

CODEXBAR_BIN="${CODEXBAR_BIN:-$(command -v codexbar || true)}"
CODEXBAR_ICON_FONT="CodexBar Provider Icons:Regular:15.0"
CODEXBAR_LABEL_WIDTH=70
STATE_DIR="$HOME/.cache/sketchybar"
STATE_FILE="$STATE_DIR/codexbar_provider"
CACHE_FILE="$STATE_DIR/codexbar_usage.json"
COUNT_FILE="$STATE_DIR/codexbar_provider_count"

if [[ -z "$CODEXBAR_BIN" && -x /opt/homebrew/bin/codexbar ]]; then
	CODEXBAR_BIN="/opt/homebrew/bin/codexbar"
fi

provider_icon_hex() {
	case "$1" in
	codex) printf '%s\n' "E000" ;;
	claude) printf '%s\n' "E001" ;;
	cursor) printf '%s\n' "E002" ;;
	opencode) printf '%s\n' "E003" ;;
	opencodego) printf '%s\n' "E004" ;;
	alibaba-coding-plan) printf '%s\n' "E005" ;;
	factory) printf '%s\n' "E006" ;;
	gemini) printf '%s\n' "E007" ;;
	antigravity) printf '%s\n' "E008" ;;
	copilot) printf '%s\n' "E009" ;;
	zai) printf '%s\n' "E00A" ;;
	minimax) printf '%s\n' "E00B" ;;
	kimi | kimik2) printf '%s\n' "E00C" ;;
	kilo) printf '%s\n' "E00D" ;;
	kiro) printf '%s\n' "E00E" ;;
	vertexai) printf '%s\n' "E00F" ;;
	augment) printf '%s\n' "E010" ;;
	jetbrains) printf '%s\n' "E011" ;;
	amp) printf '%s\n' "E012" ;;
	ollama) printf '%s\n' "E013" ;;
	synthetic) printf '%s\n' "E014" ;;
	warp) printf '%s\n' "E015" ;;
	openrouter) printf '%s\n' "E016" ;;
	windsurf) printf '%s\n' "E017" ;;
	perplexity) printf '%s\n' "E018" ;;
	abacusai) printf '%s\n' "E019" ;;
	mistral) printf '%s\n' "E01A" ;;
	deepseek) printf '%s\n' "E01B" ;;
	codebuff) printf '%s\n' "E01C" ;;
	*) printf '%s\n' "E000" ;;
	esac
}

provider_icon() {
	printf '%b' "\\u$(provider_icon_hex "$1")"
}

provider_display_name() {
	case "$1" in
	codex) printf '%s\n' "Codex" ;;
	claude) printf '%s\n' "Claude" ;;
	cursor) printf '%s\n' "Cursor" ;;
	opencode) printf '%s\n' "OpenCode" ;;
	opencodego) printf '%s\n' "OpenCode Go" ;;
	alibaba-coding-plan) printf '%s\n' "Alibaba" ;;
	factory) printf '%s\n' "Factory" ;;
	gemini) printf '%s\n' "Gemini" ;;
	antigravity) printf '%s\n' "Antigravity" ;;
	copilot) printf '%s\n' "Copilot" ;;
	zai) printf '%s\n' "Z.ai" ;;
	minimax) printf '%s\n' "MiniMax" ;;
	kimi | kimik2) printf '%s\n' "Kimi" ;;
	kilo) printf '%s\n' "Kilo" ;;
	kiro) printf '%s\n' "Kiro" ;;
	vertexai) printf '%s\n' "Vertex AI" ;;
	augment) printf '%s\n' "Augment" ;;
	jetbrains) printf '%s\n' "JetBrains" ;;
	amp) printf '%s\n' "Amp" ;;
	ollama) printf '%s\n' "Ollama" ;;
	synthetic) printf '%s\n' "Synthetic" ;;
	warp) printf '%s\n' "Warp" ;;
	openrouter) printf '%s\n' "OpenRouter" ;;
	windsurf) printf '%s\n' "Windsurf" ;;
	perplexity) printf '%s\n' "Perplexity" ;;
	abacusai) printf '%s\n' "Abacus" ;;
	mistral) printf '%s\n' "Mistral" ;;
	deepseek) printf '%s\n' "DeepSeek" ;;
	codebuff) printf '%s\n' "Codebuff" ;;
	*) printf '%s\n' "$1" ;;
	esac
}

format_percent() {
	awk -v value="$1" 'BEGIN {
		if (value == "") exit
		value += 0
		if (value == int(value)) printf "%d%%", value
		else printf "%.1f%%", value
	}'
}

remaining_percent() {
	awk -v used="$1" 'BEGIN {
		if (used == "") exit
		remaining = 100 - used
		if (remaining < 0) remaining = 0
		if (remaining > 100) remaining = 100
		if (remaining == int(remaining)) printf "%d", remaining
		else printf "%.1f", remaining
	}'
}

window_label() {
	case "$1" in
	300) printf '%s\n' "5h" ;;
	10080) printf '%s\n' "7d" ;;
	43200) printf '%s\n' "30d" ;;
	"") printf '%s\n' "$2" ;;
	*)
		if (( "$1" >= 1440 )); then
			printf '%dd\n' $(( "$1" / 1440 ))
		elif (( "$1" >= 60 )); then
			printf '%dh\n' $(( "$1" / 60 ))
		else
			printf '%dm\n' "$1"
		fi
		;;
	esac
}

format_usage() {
	local provider="$1"
	local primary_percent="$2"
	local primary_window="$3"
	local secondary_percent="$4"
	local secondary_window="$5"
	local tertiary_percent="$6"
	local tertiary_window="$7"
	local openrouter_percent="$8"
	local openrouter_balance="$9"
	local openrouter_key_limit="${10}"
	local openrouter_key_usage="${11}"
	local parts=()
	local balance key_remaining percent

	if [[ "$provider" = "openrouter" && -n "$openrouter_percent" ]]; then
		if [[ -n "$openrouter_key_limit" && -n "$openrouter_key_usage" ]]; then
			key_remaining="$(awk -v limit="$openrouter_key_limit" -v usage="$openrouter_key_usage" 'BEGIN {
				remaining = limit - usage
				if (remaining < 0) remaining = 0
				printf "$%.2f/key", remaining
			}')"
			parts+=("$key_remaining")
		fi
		if [[ -n "$openrouter_balance" ]]; then
			balance="$(awk -v value="$openrouter_balance" 'BEGIN { printf "$%.2f", value }')"
			parts+=("$balance")
		fi
		if [[ "${#parts[@]}" -eq 0 ]]; then
			percent="$(remaining_percent "$openrouter_percent")"
			parts+=("$(format_percent "$percent")/key")
		fi
	elif [[ "$provider" = "copilot" ]]; then
		if [[ -n "$primary_percent" ]]; then
			parts+=("$(format_percent "$(remaining_percent "$primary_percent")")")
		fi
	else
		if [[ -n "$primary_percent" ]]; then
			parts+=("$(format_percent "$(remaining_percent "$primary_percent")")/$(window_label "$primary_window" "P")")
		fi

		if [[ -n "$secondary_percent" ]]; then
			parts+=("$(format_percent "$(remaining_percent "$secondary_percent")")/$(window_label "$secondary_window" "S")")
		fi

		if [[ -n "$tertiary_percent" ]]; then
			parts+=("$(format_percent "$(remaining_percent "$tertiary_percent")")/$(window_label "$tertiary_window" "T")")
		fi
	fi

	# Output line1 and line2 separated by |
	if [[ "${#parts[@]}" -eq 0 ]]; then
		printf 'n/a|\n'
	elif [[ "${#parts[@]}" -eq 1 ]]; then
		printf '%s|\n' "${parts[0]}"
	else
		local rest=("${parts[@]:1}")
		printf '%s|%s\n' "${parts[0]}" "${rest[*]}"
	fi
}

remaining_color() {
	local min_remaining="$1"

	if (( min_remaining <= 10 )); then
		printf '%s\n' "$RED"
	elif (( min_remaining <= 30 )); then
		printf '%s\n' "$ORANGE"
	elif (( min_remaining <= 60 )); then
		printf '%s\n' "$YELLOW"
	else
		printf '%s\n' "$GREEN"
	fi
}

set_error() {
	sketchybar --set "$NAME" \
		icon="!" \
		icon.font="$FONT:Bold:13.0" \
		icon.drawing=on \
		icon.color="$RED" \
		label.color="$RED" \
		label="$1" \
		label.drawing=on
	sketchybar --set codexbar.l1 drawing=off
	sketchybar --set codexbar.l2 drawing=off
}

mkdir -p "$STATE_DIR"

is_select=false
if [[ "$1" = "select" && -n "$2" ]]; then
	is_select=true
	printf '%s\n' "$2" >"$STATE_FILE"
	sketchybar --set codexbar popup.drawing=off
fi

case "$SENDER" in
mouse.entered)
	provider_count=0
	if [[ -f "$COUNT_FILE" ]]; then
		provider_count="$(<"$COUNT_FILE")"
	fi
	if (( provider_count > 1 )); then
		sketchybar --set codexbar popup.drawing=on
	fi
	exit 0
	;;
mouse.exited | mouse.exited.global)
	sketchybar --set codexbar popup.drawing=off
	exit 0
	;;
esac

if [[ -z "$CODEXBAR_BIN" && "$is_select" = false ]]; then
	set_error "missing"
	exit 0
fi

json=""
if [[ "$is_select" = true && -f "$CACHE_FILE" ]]; then
	json="$(<"$CACHE_FILE")"
fi

if [[ -z "$json" ]]; then
	raw="$("$CODEXBAR_BIN" usage --json-only 2>/dev/null)"
	json="$(printf '%s\n' "$raw" | awk '/^\[/{found=1} found{print}' | jq -c 'map(select(.error | not))' 2>/dev/null)"
	if [[ -n "$json" ]]; then
		printf '%s\n' "$json" >"$CACHE_FILE"
	fi
fi

if [[ -z "$json" ]]; then
	set_error "error"
	exit 0
fi

if [[ "$(printf '%s\n' "$json" | jq 'length' 2>/dev/null)" = "0" ]]; then
	set_error "error"
	exit 0
fi

provider_count="$(printf '%s\n' "$json" | jq 'length' 2>/dev/null)"
printf '%s\n' "$provider_count" >"$COUNT_FILE"

selected_provider=""
if [[ -f "$STATE_FILE" ]]; then
	selected_provider="$(<"$STATE_FILE")"
fi

if [[ -z "$selected_provider" ]] || ! printf '%s\n' "$json" | jq -e --arg provider "$selected_provider" 'any(.[]; .provider == $provider)' >/dev/null; then
	selected_provider="$(printf '%s\n' "$json" | jq -r 'if any(.[]; .provider == "codex") then "codex" else .[0].provider end')"
	printf '%s\n' "$selected_provider" >"$STATE_FILE"
fi

sketchybar --set '/codexbar\..*/' drawing=off

while IFS= read -r provider_json; do
	provider="$(printf '%s\n' "$provider_json" | jq -r '.provider')"
	primary="$(printf '%s\n' "$provider_json" | jq -r '.usage.primary.usedPercent // empty')"
	primary_window="$(printf '%s\n' "$provider_json" | jq -r '.usage.primary.windowMinutes // empty')"
	secondary="$(printf '%s\n' "$provider_json" | jq -r '.usage.secondary.usedPercent // empty')"
	secondary_window="$(printf '%s\n' "$provider_json" | jq -r '.usage.secondary.windowMinutes // empty')"
	tertiary="$(printf '%s\n' "$provider_json" | jq -r '.usage.tertiary.usedPercent // empty')"
	tertiary_window="$(printf '%s\n' "$provider_json" | jq -r '.usage.tertiary.windowMinutes // empty')"
	openrouter_percent="$(printf '%s\n' "$provider_json" | jq -r '.usage.openRouterUsage.usedPercent // empty')"
	openrouter_balance="$(printf '%s\n' "$provider_json" | jq -r '.usage.openRouterUsage.balance // empty')"
	openrouter_key_limit="$(printf '%s\n' "$provider_json" | jq -r '.usage.openRouterUsage.keyLimit // empty')"
	openrouter_key_usage="$(printf '%s\n' "$provider_json" | jq -r '.usage.openRouterUsage.keyUsage // empty')"
	usage="$(format_usage "$provider" "$primary" "$primary_window" "$secondary" "$secondary_window" "$tertiary" "$tertiary_window" "$openrouter_percent" "$openrouter_balance" "$openrouter_key_limit" "$openrouter_key_usage")"
	label_line1="${usage%%|*}"
	label_line2="${usage#*|}"
	display_name="$(provider_display_name "$provider")"
	icon="$(provider_icon "$provider")"
	min_remaining="$(awk \
		-v a="$(remaining_percent "${primary:-}")" \
		-v b="$(remaining_percent "${secondary:-}")" \
		-v c="$(remaining_percent "${tertiary:-}")" \
		-v d="$(remaining_percent "${openrouter_percent:-}")" \
		'BEGIN {
		min = 101
		if (a != "" && a < min) min = a
		if (b != "" && b < min) min = b
		if (c != "" && c < min) min = c
		if (d != "" && d < min) min = d
		if (min == 101) min = 100
		printf "%d", min
	}')"
	color="$(remaining_color "$min_remaining")"
	item="codexbar.${provider}"
	background_color="$POPUP_BACKGROUND_COLOR"

	if [[ "$provider" = "$selected_provider" ]]; then
		background_color="$HOVER_COLOR"
		sketchybar --set codexbar \
			icon="$icon" \
			icon.font="$CODEXBAR_ICON_FONT" \
			icon.color="$color" \
			icon.drawing=on
		if [[ -n "$label_line2" ]]; then
			sketchybar --set codexbar \
				label.drawing=off
			sketchybar --set codexbar.l1 \
				label.color="$color" \
				label="$label_line1" \
				label.width="$CODEXBAR_LABEL_WIDTH" \
				y_offset=6 \
				padding_right=-$CODEXBAR_LABEL_WIDTH \
				drawing=on
			sketchybar --set codexbar.l2 \
				label.color="$color" \
				label="$label_line2" \
				drawing=on
		else
			sketchybar --set codexbar \
				label.color="$color" \
				label="$label_line1" \
				label.drawing=on
			sketchybar --set codexbar.l1 drawing=off
			sketchybar --set codexbar.l2 drawing=off
		fi
	fi

	popup_label="${display_name} ${label_line1}$([[ -n "$label_line2" ]] && printf ' %s' "$label_line2")"
	sketchybar --set "$item" \
		drawing="$([[ "$provider_count" -gt 1 ]] && printf on || printf off)" \
		icon="$icon" \
		icon.font="$CODEXBAR_ICON_FONT" \
		icon.color="$color" \
		icon.drawing=on \
		label="$popup_label" \
		label.color="$color" \
		background.color="$background_color"
done < <(printf '%s\n' "$json" | jq -c '.[]')
