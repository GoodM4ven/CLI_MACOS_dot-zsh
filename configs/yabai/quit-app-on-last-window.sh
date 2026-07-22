#!/usr/bin/env sh

# Quit certain apps once their last window closes. macOS keeps browsers and
# similar apps running in the background after the final window is closed
# (dock icon + helper processes stay alive), and Chromium-based apps like
# Helium have no native "quit on last window" setting. This is wired into
# yabai's window_destroyed signal.
#
# Apps that expose the setting natively (e.g. Zed's
# "on_last_window_closed": "quit_app") should use that instead and be left
# out of the list below.

# Space-separated list of app names (as reported by `yabai -m query --windows`).
WATCHED="Helium"

windows="$(yabai -m query --windows 2>/dev/null)"
[ -z "$windows" ] && exit 0

for app in $WATCHED; do
  # Only act on apps that are actually running.
  pgrep -x "$app" >/dev/null 2>&1 || continue

  # Count remaining windows for this app (minimized windows still count, so a
  # minimized-only app is left alone).
  count="$(printf '%s' "$windows" | jq --arg a "$app" '[.[] | select(.app == $a)] | length')"

  if [ "$count" = "0" ]; then
    osascript -e "tell application \"$app\" to quit" >/dev/null 2>&1
  fi
done
