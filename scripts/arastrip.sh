#!/usr/bin/env bash

# arastrip.sh — Strips out harakat and weird Arabic characters from a provided text

set -euo pipefail
export LC_ALL=C.UTF-8

if [[ -t 0 ]]; then
  # No stdin → use arguments
  if [[ $# -eq 0 ]]; then
    echo "Provide Arabic text via arguments or stdin."
    exit 1
  fi
  input="$*"
else
  # Read from stdin
  input=$(cat)
fi

output=$(
  printf '%s' "$input" \
  | sed 's/ٱ/ا/g' \
  | perl -CSD -pe 's/\p{M}//g'
)

printf '%s\n' "$output"
