#!/bin/bash

output="$(python3 "$HOME/.config/sketchybar/plugins/prayer.py" 2>/dev/null)"
time_left="${output%%|*}"
arabic_name="${output#*|}"

if [[ -z "$output" || "$arabic_name" == "--" ]]; then
  sketchybar --set prayer label="--:--"
else
  sketchybar --set prayer label="$time_left - $arabic_name"
fi
