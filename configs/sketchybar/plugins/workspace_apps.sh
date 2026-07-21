#!/bin/bash
set -u

# Rapid window/space events (e.g. moving a window to the next space, which
# fires window_moved and space_changed back to back) each spawn a fresh
# instance of this script. Their `yabai -m query` calls can finish out of
# order, so a slower, older run can overwrite the label with stale data
# after a newer run already drew the correct one. Stamp each run with a
# token and skip the final `--set` if a newer run has since started.
token_file="/tmp/sketchybar-workspace-apps.token"
my_token="$(date +%s%N)"
printf '%s' "$my_token" > "$token_file"

json="$(yabai -m query --windows --space 2>/dev/null || printf '[]')"

[[ "$(cat "$token_file" 2>/dev/null)" == "$my_token" ]] || exit 0

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
      #
      # yabai reports "" (not null) for role/subrole on some apps (e.g.
      # Electron-based ones), so `// default` alone does not catch it --
      # treat both null and "" as "unknown, assume standard window".
      select((.role == null or .role == "" or .role == "AXWindow"))
      | select((.subrole == null or .subrole == "" or .subrole == "AXStandardWindow"))
      | select((."is-visible" // false) == true)
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
    awk '
      NF {
        count[$0]++
        if (!seen[$0]++) order[++n] = $0
      }
      END {
        for (i = 1; i <= n; i++) {
          app = order[i]
          print (count[app] > 1) ? app " (" count[app] ")" : app
        }
      }
    ' |
    paste -sd '|' -
)"

[[ "$(cat "$token_file" 2>/dev/null)" == "$my_token" ]] || exit 0

if [[ -z "$apps" ]]; then
  label="No open windows"
else
  label="$(printf '%s' "$apps" | sed 's/|/  |  /g')"
fi

sketchybar --set workspace_apps label="$label"
