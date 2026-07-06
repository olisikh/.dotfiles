#!/usr/bin/env bash

MACMON=$(command -v macmon)
LAST_FILE="/tmp/sketchybar_temperature_last"

if [ -z "$MACMON" ]; then
	sketchybar --set temperature label=" --"
	exit 0
fi

json=$($MACMON pipe -s 1 -i 3000 2>/dev/null)

if [ -z "$json" ]; then
	sketchybar --set temperature label=" --"
	exit 0
fi

raw_temperature=$(printf '%s\n' "$json" | python3 -c '
import json
import sys

try:
    data = json.load(sys.stdin)
except Exception:
    print("")
    raise SystemExit(0)

temp = data.get("temp") or {}
cpu = temp.get("cpu_temp_avg")
gpu = temp.get("gpu_temp_avg")

values = [value for value in (cpu, gpu) if isinstance(value, (int, float)) and value > 0]

if values:
    print(f"{sum(values) / len(values):.1f}")
')

[ -z "$raw_temperature" ] && raw_temperature="--"

if [ "$raw_temperature" = "--" ]; then
	sketchybar --set temperature label=" --"
	exit 0
fi

temperature=$(
	python3 - "$LAST_FILE" "$raw_temperature" <<'PY'
import sys
from pathlib import Path

history_path = Path(sys.argv[1])
current = float(sys.argv[2])

history = []
if history_path.exists():
    for line in history_path.read_text().splitlines():
        try:
            history.append(float(line.strip()))
        except ValueError:
            pass

history.append(current)
history = history[-3:]
history_path.write_text("\n".join(f"{value:.1f}" for value in history) + "\n")

print(f"{sum(history) / len(history):.1f}")
PY
)

sketchybar --set temperature label=" ${temperature}°"
