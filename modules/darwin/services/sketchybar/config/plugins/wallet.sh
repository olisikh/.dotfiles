#!/usr/bin/env bash
export SOPS_AGE_KEY_FILE="${HOME}/.config/sops/age/keys.txt"

LOG_FILE="${HOME}/.cache/sketchybar/wallet_debug.log"
mkdir -p "$(dirname "${LOG_FILE}")"

# Load and decrypt all SOPS secrets into JSON once for efficient parsing
if ! secrets_json=$(sops --output-type json -d "${HOME}/.config/sops/secrets.yaml" 2>>"$LOG_FILE"); then
	echo "$(date '+%Y-%m-%d %H:%M:%S') DEBUG: sops failed to decrypt secrets.yaml" >>"$LOG_FILE"
	secrets_json="{}"
fi

OPENROUTER_API_KEY=$(jq -r '.openrouter // ""' <<<"${secrets_json}")

# Fetch balance from given API key and endpoint, formatted or N/A
get_balance() {
	if [ -n "$1" ]; then
		response=$(curl -s "$2" -H "Authorization: Bearer $1" -H "Content-Type: application/json")
		credits=$(jq -r '.data.total_credits // empty' <<<"$response" 2>/dev/null)
		usage=$(jq -r '.data.total_usage // empty' <<<"$response" 2>/dev/null)
		balance=$(awk -v c="$credits" -v u="$usage" 'BEGIN {printf "%.2f", c - u}')

		if [ -n "$credits" ]; then
			printf "%s$" "$balance"
		else
			echo "N/A"
		fi
	else
		echo "N/A"
	fi
}

OR_BALANCE=$(get_balance "$OPENROUTER_API_KEY" "https://openrouter.ai/api/v1/credits")

echo "$(date '+%Y-%m-%d %H:%M:%S') OR: $OR_BALANCE" >>"$LOG_FILE"

# Opencode balance can't be fetcvhed using API
sketchybar --set "$NAME" label="OR: $OR_BALANCE"
