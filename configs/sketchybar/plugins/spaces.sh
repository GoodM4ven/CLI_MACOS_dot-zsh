#!/bin/bash

current="$(yabai -m query --spaces --space 2>/dev/null | jq -r '.index // empty')"
existing="$(yabai -m query --spaces 2>/dev/null | jq -r '.[].index')"

[[ -z "$current" ]] && exit 0

for i in {1..9}; do
  if printf '%s\n' "$existing" | grep -qx "$i"; then
    if [[ "$i" == "$current" ]]; then
      sketchybar --set "space.$i" drawing=on icon.color=0xFF1E2030 background.drawing=on background.color=0xFFC6A0F6
    else
      sketchybar --set "space.$i" drawing=on icon.color=0xFFF4F4F5 background.drawing=off
    fi
  else
    sketchybar --set "space.$i" drawing=off background.drawing=off
  fi
done
