#!/bin/bash

source "$HOME/.config/sketchybar/icons.sh"

info="$(pmset -g batt 2>/dev/null)"
percent="$(printf '%s\n' "$info" | grep -Eo '[0-9]+%' | head -n 1)"
[[ -z "$percent" ]] && percent="--%"

if printf '%s\n' "$info" | grep -Eqi '[;[:space:]](charging|finishing charge)([;[:space:]]|$)'; then
  icon="$ICON_BATTERY_CHARGING"
else
  icon="$ICON_BATTERY_100"
fi

sketchybar --set battery icon="$icon" label="$percent"
