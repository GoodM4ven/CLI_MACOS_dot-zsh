#!/bin/bash

# Keep yabai's full-display grid below SketchyBar and provide a simple
# maximize -> centered window -> minimize cycle for Option+Down.
set -u

YABAI=/opt/homebrew/bin/yabai
STATE_DIR=/tmp/yabai-window-layout
LAST_MINIMIZED="$STATE_DIR/last-minimized"
mkdir -p "$STATE_DIR"

# The Dock-minimized window is no longer focused. Restore the last one we
# minimized before applying the normal centered-window half of the toggle.
if [[ -s "$LAST_MINIMIZED" ]]; then
  minimized_id="$(<"$LAST_MINIMIZED")"
  minimized_json="$($YABAI -m query --windows --window "$minimized_id" 2>/dev/null)" || minimized_json=''
  if [[ "$(printf '%s' "$minimized_json" | /usr/bin/jq -r '."is-minimized" // false')" == true ]]; then
    "$YABAI" -m window --deminimize "$minimized_id" 2>/dev/null || true
    "$YABAI" -m window --focus "$minimized_id" 2>/dev/null || true
    sleep 0.1
    restored_json="$($YABAI -m query --windows --window 2>/dev/null)" || exit 0
    if [[ "$(printf '%s' "$restored_json" | /usr/bin/jq -r '."is-floating"')" != true ]]; then
      "$YABAI" -m window --toggle float 2>/dev/null || true
    fi
    "$YABAI" -m window --grid 10:10:1:1:8:8
    rm -f "$LAST_MINIMIZED"
    exit 0
  fi
  rm -f "$LAST_MINIMIZED"
fi

window_json="$($YABAI -m query --windows --window 2>/dev/null)" || exit 0
window_id="$(printf '%s' "$window_json" | /usr/bin/jq -r '.id')"

case "${1:-}" in
  maximize)
    "$YABAI" -m window --toggle float 2>/dev/null || true
    "$YABAI" -m window --grid 1:1:0:0:1:1
    printf '%s\n' maximized > "$STATE_DIR/$window_id"
    ;;
  toggle-down)
    is_floating="$(printf '%s' "$window_json" | /usr/bin/jq -r '."is-floating"')"
    frame="$(printf '%s' "$window_json" | /usr/bin/jq -r '.frame | [.x,.y,.w,.h] | @tsv')"
    display="$(printf '%s' "$window_json" | /usr/bin/jq -r '.display')"
    display_json="$($YABAI -m query --displays | /usr/bin/jq -c --argjson id "$display" '.[] | select(.id == $id)')"
    read -r dx dy dw dh <<< "$(printf '%s' "$display_json" | /usr/bin/jq -r '.frame | [.x,.y,.w,.h] | @tsv')"

    # A centered 80% window is the closest reliable cross-app equivalent of
    # restoring a window's natural size after yabai has maximized it.
    centered_grid='10:10:1:1:8:8'
    if [[ "$(printf '%s' "$frame" | awk -v x="$dx" -v y="$dy" -v w="$dw" -v h="$dh" '{print ($1==x && $2==y && $3==w && $4==h) ? "max" : "other"}')" == max ]]; then
      if [[ "$is_floating" != true ]]; then
        "$YABAI" -m window --toggle float 2>/dev/null || true
      fi
      "$YABAI" -m window --grid "$centered_grid"
      printf '%s\n' centered > "$STATE_DIR/$window_id"
    else
      "$YABAI" -m window --minimize
      printf '%s\n' minimized > "$STATE_DIR/$window_id"
      printf '%s\n' "$window_id" > "$LAST_MINIMIZED"
    fi
    ;;
esac
