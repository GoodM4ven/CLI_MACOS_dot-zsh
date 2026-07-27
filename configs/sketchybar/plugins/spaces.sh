#!/bin/bash

source "$HOME/.config/sketchybar/colors.sh"

# Scroll to navigate spaces while hovering the bar. SCROLL_DELTA sign follows
# macOS's scroll direction setting; flip the two branches below if it feels
# backwards on your machine.
if [[ "$SENDER" == "mouse.scrolled.global" ]]; then
  existing_spaces="$(yabai -m query --spaces 2>/dev/null | jq -r '.[].index' | sort -n)"
  scroll_current="$(yabai -m query --spaces --space 2>/dev/null | jq -r '.index // empty')"

  if [[ -n "$scroll_current" ]]; then
    if (( SCROLL_DELTA < 0 )); then
      # Scroll down -> forward to the next space
      target="$(printf '%s\n' "$existing_spaces" | awk -v c="$scroll_current" 'found{print; exit} $0==c{found=1}')"
    else
      # Scroll up -> back to the previous space
      target="$(printf '%s\n' "$existing_spaces" | awk -v c="$scroll_current" '$0==c{print prev; exit} {prev=$0}')"
    fi
    [[ -n "$target" ]] && yabai -m space --focus "$target"
  fi
fi

current="$(yabai -m query --spaces --space 2>/dev/null | jq -r '.index // empty')"
existing="$(yabai -m query --spaces 2>/dev/null | jq -r '.[].index')"

[[ -z "$current" ]] && exit 0

for i in {1..9}; do
  if printf '%s\n' "$existing" | grep -qx "$i"; then
    if [[ "$i" == "$current" ]]; then
      sketchybar --set "space.$i" drawing=on icon.color=$ACTIVE_TEXT_COLOR background.drawing=on background.color=$ACTIVE_COLOR
    else
      sketchybar --set "space.$i" drawing=on icon.color=0xFFF4F4F5 background.drawing=off
    fi
  else
    sketchybar --set "space.$i" drawing=off background.drawing=off
  fi
done
