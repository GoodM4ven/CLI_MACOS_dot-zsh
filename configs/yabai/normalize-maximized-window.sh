#!/bin/bash

# Normalize only windows that were created at the exact full-display frame.
# Normally sized windows are deliberately left alone.
set -u

YABAI=/opt/homebrew/bin/yabai
JQ=/usr/bin/jq

# Chromium-based apps can finish laying out their new window well after the
# window_created/window_focused signals fire. Retry briefly below.
sleep 0.15

window_id="${YABAI_WINDOW_ID:-}"
if [[ -z "$window_id" ]]; then
  window_id="$($YABAI -m query --windows --window 2>/dev/null | "$JQ" -r '.id // empty')"
fi
[[ -n "$window_id" ]] || exit 0

for _ in {1..12}; do
  window_json="$($YABAI -m query --windows --window "$window_id" 2>/dev/null)" || exit 0
  [[ -n "$window_json" ]] || exit 0

  # Native fullscreen is a separate macOS mode and should not be touched.
  [[ "$(printf '%s' "$window_json" | "$JQ" -r '."is-native-fullscreen" // false')" == true ]] && exit 0

  display_id="$(printf '%s' "$window_json" | "$JQ" -r '.display // empty')"
  [[ -n "$display_id" ]] || exit 0
  display_json="$($YABAI -m query --displays 2>/dev/null | "$JQ" -c --argjson id "$display_id" '.[] | select(.id == $id)')" || exit 0
  [[ -n "$display_json" ]] || exit 0

  window_frame="$(printf '%s' "$window_json" | "$JQ" -r '.frame | [.x,.y,.w,.h] | @tsv')"
  display_frame="$(printf '%s' "$display_json" | "$JQ" -r '.frame | [.x,.y,.w,.h] | @tsv')"

  # Recognize both raw full-display frames and windows that already have the
  # correct usable height but incorrectly start at y=0 behind SketchyBar.
  full_like="$(awk -v wf="$window_frame" -v df="$display_frame" 'BEGIN {
    split(wf, w); split(df, d)
    print (w[1] == d[1] && w[3] == d[3] && w[2] == d[2] && w[4] >= d[4] - 30 && w[4] <= d[4] + 1) ? "yes" : "no"
  }')"
  if [[ "$full_like" == yes ]]; then
    # Reuse the same SketchyBar-aware grid used by Option+Up.
    if [[ "$(printf '%s' "$window_json" | "$JQ" -r '."is-floating" // false')" != true ]]; then
      "$YABAI" -m window --toggle float 2>/dev/null || true
    fi
    "$YABAI" -m window --grid 1:1:0:0:1:1 2>/dev/null || true
    exit 0
  fi
  sleep 0.15
done
