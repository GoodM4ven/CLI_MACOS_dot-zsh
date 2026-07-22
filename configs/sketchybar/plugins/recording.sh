#!/bin/bash

item_name="${NAME:-recording}"
obs_log_dir="$HOME/Library/Application Support/obs-studio/logs"

# A previous session can end without a Stop marker if OBS crashes, so require
# the OBS process to be alive before trusting the current session log.
if ! pgrep -x OBS >/dev/null 2>&1 || [ ! -d "$obs_log_dir" ]; then
  sketchybar --set "$item_name" drawing=off
  exit 0
fi

# OBS log names begin with an ISO-style timestamp, so lexical order identifies
# the log for the currently running (most recent) OBS session.
latest_log=$(find "$obs_log_dir" -maxdepth 1 -type f -name '*.txt' -print 2>/dev/null | LC_ALL=C sort | tail -n 1)

if [ -z "$latest_log" ]; then
  sketchybar --set "$item_name" drawing=off
  exit 0
fi

last_record_event=$(grep -E '==== Recording (Start|Stop)' "$latest_log" 2>/dev/null | tail -n 1)

case "$last_record_event" in
  *"Recording Start"*) sketchybar --set "$item_name" drawing=on ;;
  *)                   sketchybar --set "$item_name" drawing=off ;;
esac
