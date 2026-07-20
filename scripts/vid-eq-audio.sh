#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

[[ -z "${1:-}" ]] && { echo "Usage: vid-eq-audio <input> [output]"; exit 1; }

start_time=$(date +%s)

in="$1"
out="${2:-output.mp4}"

log "Starting audio processing"
log "Input: $in"
log "Output: $out"

ffmpeg -hide_banner -stats -i "$in" \
-af "aresample=48000,\
afftdn=nf=-22,\
highpass=f=80,\
dynaudnorm=f=250:g=11,\
loudnorm=I=-16:TP=-2:LRA=11" \
-ar 48000 \
-c:v copy \
-c:a aac -b:a 192k \
"$out"

end_time=$(date +%s)
duration=$((end_time - start_time))

log "Finished processing"
log "Total time: ${duration}s"