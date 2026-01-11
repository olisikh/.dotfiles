#!/usr/bin/env bash

LOG_FILE="${HOME}/.cache/sketchybar/wallet_debug.log"
mkdir -p "$(dirname "${LOG_FILE}")"

# Load and decrypt all SOPS secrets into JSON once for efficient parsing
secrets_json=$(sops --output-type json -d "${HOME}/.config/sops/secrets.yaml")

OPENROUTER_API_KEY=$(jq -r '.openrouter // ""' <<<"${secrets_json}")
OPENCODE_API_KEY=$(jq -r '.opencode // ""' <<<"${secrets_json}")

# Fetch balance from given API key and endpoint, formatted or N/A
get_balance() {
	[ -n "$1" ] &&
		curl -s "$2" -H "Authorization: Bearer $1" -H "Content-Type: application/json" |
		jq -r '.data.credits // ""' | awk '{printf "%.2f$", $0}' || echo "N/A"
}

OR_BALANCE=$(get_balance "$OPENROUTER_API_KEY" "https://openrouter.ai/api/v1/auth/key")
OC_BALANCE=$(get_balance "$OPENCODE_API_KEY" "https://opencode.ai/api/v1/auth/key")

echo "$(date '+%Y-%m-%d %H:%M:%S') OR: $OR_BALANCE, OC: $OC_BALANCE" >>"$LOG_FILE"
sketchybar --set "$NAME" label="OR: $OR_BALANCE, OC: $OC_BALANCE"
