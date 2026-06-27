#!/usr/bin/env bash

cpu_percent=$(ps -A -o %cpu | awk '{s+=$1} END {s /= 8; printf "%.1f%%", s}')

memory_stats=$(vm_stat)
pages_wired=$(echo "$memory_stats" | awk '/Pages wired down/ {print $4}' | tr -d '.')
pages_active=$(echo "$memory_stats" | awk '/Pages active/ {print $3}' | tr -d '.')
pages_compressed=$(echo "$memory_stats" | awk '/Pages occupied by compressor/ {print $5}' | tr -d '.')

page_size=$(sysctl -n hw.pagesize)
used_mem=$(((pages_wired + pages_active + pages_compressed) * page_size))
total_mem=$(sysctl -n hw.memsize)
used_percent=$(awk -v used="$used_mem" -v total="$total_mem" 'BEGIN {printf "%.1f%%", used / total * 100}')

sketchybar --set cpu_memory_cpu label=" ${cpu_percent}" \
	--set cpu_memory_memory label="󰘚 ${used_percent}"
