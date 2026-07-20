#!/usr/bin/env bash
set -euo pipefail

[[ $# -lt 2 ]] && {
  echo "Usage: vid-combine <file1.mp4 ... | list.txt> <output.mp4>"
  exit 1
}

out="${@: -1}"
inputs=("${@:1:$#-1}")

tmp_list="$(mktemp)"
tmp_dir="$(mktemp -d)"

add_file() {
  local src="$1"
  local fixed="$tmp_dir/$(basename "$src")"

  # Normalize timestamps without re-encoding
  ffmpeg -y -fflags +genpts -i "$src" \
    -map 0 -c copy \
    -avoid_negative_ts make_zero \
    "$fixed" >/dev/null 2>&1

  echo "file '$fixed'" >> "$tmp_list"
}

if [[ "${inputs[0]}" == *.txt ]]; then
  while IFS= read -r f; do
    [[ -n "$f" ]] && add_file "$(realpath "$f")"
  done < "${inputs[0]}"
else
  for f in "${inputs[@]}"; do
    add_file "$(realpath "$f")"
  done
fi

ffmpeg -f concat -safe 0 -i "$tmp_list" \
  -c copy \
  -movflags +faststart \
  "$out"

rm -rf "$tmp_list" "$tmp_dir"
