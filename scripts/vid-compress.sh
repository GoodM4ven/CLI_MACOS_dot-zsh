#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

usage() {
  echo "Usage: vid-compress [-1080|-720] [-lq] [-mobile|-portrait] <input> [output]"
  exit 1
}

start_time=$(date +%s)

scale_filter=""
crf=23
preset="medium"
codec="libx265"
mobile_mode=false

while [[ "${1:-}" == -* ]]; do
  case "$1" in
    -1080)
      scale_filter="scale=-2:1080"
      shift
      ;;
    -720)
      scale_filter="scale=-2:720"
      shift
      ;;
    -lq)
      crf=25
      shift
      ;;
    -mobile|-portrait)
      mobile_mode=true
      shift
      ;;
    *)
      usage
      ;;
  esac
done

[[ -z "${1:-}" ]] && usage

in="$1"
out="${2:-output.mp4}"

if $mobile_mode; then
  codec="libx264"
  preset="veryfast"
  crf=27

  # only set scaling if user did not specify one
  if [[ -z "$scale_filter" ]]; then
    scale_filter="scale=-2:'min(1080,ih)'"
  fi
fi

log "Starting compression"
log "Input: $in"
log "Output: $out"
log "Codec: $codec"
log "Preset: $preset"
log "CRF: $crf"
[[ -n "$scale_filter" ]] && log "Scaling: $scale_filter"
$mobile_mode && log "Mobile mode enabled"

vf_args=()
[[ -n "$scale_filter" ]] && vf_args=(-vf "$scale_filter")

log "Encoding..."

if [[ "$codec" == "libx265" ]]; then
  ffmpeg \
    -threads 0 \
    -hide_banner \
    -stats \
    -i "$in" \
    "${vf_args[@]}" \
    -map_metadata -1 \
    -c:v libx265 \
    -preset "$preset" \
    -crf "$crf" \
    -x265-params "pools=16:frame-threads=4:wpp=1" \
    -tag:v hvc1 \
    -c:a aac -b:a 96k \
    -movflags +faststart \
    "$out"
else
  ffmpeg \
    -threads 0 \
    -hide_banner \
    -stats \
    -i "$in" \
    "${vf_args[@]}" \
    -map_metadata -1 \
    -c:v libx264 \
    -preset "$preset" \
    -crf "$crf" \
    -c:a aac -b:a 96k \
    -movflags +faststart \
    "$out"
fi

end_time=$(date +%s)
duration=$((end_time - start_time))

log "Finished compression"
log "Total time: ${duration}s"