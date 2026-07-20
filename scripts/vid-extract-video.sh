#!/usr/bin/env bash
set -e

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

[[ -z "$1" ]] && { echo "Usage: vid-extract-video <input> [start] [end] [output]"; exit 1; }

in="$1"
start="$(normalize_ts "$2")"
end="$(normalize_ts "$3")"
out="${4:-output.mp4}"

args=()
[[ -n "$start" ]] && args+=(-ss "$start")
args+=(-i "$in")
[[ -n "$end" ]] && args+=(-to "$end")

args+=(-c:v libx264 -c:a aac "$out")

ffmpeg "${args[@]}"
