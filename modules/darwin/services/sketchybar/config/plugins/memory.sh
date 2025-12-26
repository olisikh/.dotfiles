#!/usr/bin/env bash

memory_stats=$(vm_stat)
pages_wired=$(echo "$memory_stats" | awk '/Pages wired down/ {print $4}' | tr -d '.')
pages_active=$(echo "$memory_stats" | awk '/Pages active/ {print $3}' | tr -d '.')
pages_compressed=$(echo "$memory_stats" | awk '/Pages occupied by compressor/ {print $5}' | tr -d '.')

page_size=$(sysctl -n hw.pagesize)

used_mem=$(((pages_wired + pages_active + pages_compressed) * page_size))
total_mem=$(sysctl -n hw.memsize)

used_percent=$(printf "%.1f%%\n" "$(echo "$used_mem / $total_mem * 100" | bc -l)")

sketchybar --set "$NAME" icon="󰘚 " label="${used_percent/,/.}"
