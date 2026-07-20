#!/bin/bash
line="$(top -l 2 -n 0 -s 0 2>/dev/null | grep 'CPU usage' | tail -n 1)"
idle="$(printf '%s' "$line" | sed -E 's/.* ([0-9.]+)% idle.*/\1/')"
if [[ "$idle" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  usage="$(awk -v idle="$idle" 'BEGIN { printf "%.0f", 100-idle }')"
else
  usage="--"
fi
sketchybar --set cpu label="${usage}%"
