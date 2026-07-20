#!/bin/bash
set -u

json="$(yabai -m query --windows --space 2>/dev/null || printf '[]')"

# Keep the raw response available for diagnostics.
printf '%s\n' "$json" > /tmp/sketchybar-yabai-current-space.json

apps="$(
  printf '%s' "$json" |
    jq -r '
      .[]
      |
      # AltTab-like filtering:
      # - actual application window
      # - standard window rather than helper/popover/background panel
      # - visible and not minimized
      select((.role // "AXWindow") == "AXWindow")
      | select((.subrole // "AXStandardWindow") == "AXStandardWindow")
      | select((."is-minimized" // false) == false)
      | select((."is-hidden" // false) == false)
      |
      # Exclude obvious non-interactive/background windows when these
      # properties are available in the installed yabai version.
      select((."is-sticky" // false) == false)
      | select((."is-native-fullscreen" // false) == false or (.space // 0) > 0)
      |
      .app // empty
    ' 2>/dev/null |
    awk 'NF && !seen[$0]++' |
    paste -sd '|' -
)"

if [[ -z "$apps" ]]; then
  label="No open windows"
else
  label="$(printf '%s' "$apps" | sed 's/|/  |  /g')"
fi

sketchybar --set workspace_apps label="$label"
