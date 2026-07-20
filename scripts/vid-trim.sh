#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: vid-trim <input> [start] [end] [output]"
  echo "Examples:"
  echo "  vid-trim in.mp4 \"\" 00:15:05 out.mp4"
  echo "  vid-trim in.mp4 00:02:10 00:15:05 out.mp4"
  exit 1
}

[[ $# -lt 1 ]] && usage

in="$1"
start_raw="${2:-}"
end_raw="${3:-}"
out="${4:-output.mp4}"

normalize_ts() {
  local ts="$1"
  [[ -z "$ts" ]] && return
  if [[ "$ts" =~ ^[0-9]+$ ]]; then
    printf "%02d:%02d:%02d" $((ts/3600)) $((ts%3600/60)) $((ts%60))
  elif [[ "$ts" =~ ^[0-9]+:[0-9]{2}$ ]]; then
    printf "00:%s" "$ts"
  else
    echo "$ts"
  fi
}

to_seconds() {
  IFS=: read -r h m s <<<"$1"
  echo $((10#$h*3600 + 10#$m*60 + 10#$s))
}

start="$(normalize_ts "$start_raw")"
end="$(normalize_ts "$end_raw")"

args=(-i "$in")

[[ -n "$start" ]] && args+=(-ss "$start")

# Inclusive end handling
if [[ -n "$end" ]]; then
  end_s=$(to_seconds "$end")
  start_s=0
  [[ -n "$start" ]] && start_s=$(to_seconds "$start")

  # +1 frame (1/30s is safe for OBS)
  duration=$(awk "BEGIN {printf \"%.3f\", ($end_s - $start_s) + 0.034}")
  args+=(-t "$duration")
fi

args+=(
  -map 0
  -c:v libx264
  -c:a aac
  -pix_fmt yuv420p
  -movflags +faststart
  -avoid_negative_ts make_zero
  "$out"
)

ffmpeg "${args[@]}"
