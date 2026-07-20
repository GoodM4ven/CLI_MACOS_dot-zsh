#!/usr/bin/env bash

# vid-pic.sh — aggressively robust video thumbnailer, for weird filenames
# Usage:
#   vid-pic.sh file.mp4 [output_dir]
#   vid-pic.sh -d /path/to/dir [output_dir]
#
# Options:
#   -f, --force        Overwrite existing JPGs (default)
#       --no-force     Skip existing JPGs
#       --debug        Print escaped/hex diagnostics for each processed path
#       --rename-clean Normalize + trim filenames on disk before processing
#
# Env:
#   THUMB_WIDTH=N      Scale width (keeps aspect), e.g. THUMB_WIDTH=480

set -Eeuo pipefail
shopt -s nullglob

FORCE=1
DEBUG=0
RENAME_CLEAN=0
THUMB_WIDTH="${THUMB_WIDTH:-}"

need() { command -v "$1" >/dev/null 2>&1 || { echo "Error: need '$1'." >&2; exit 1; }; }
need ffmpeg; need ffprobe; need awk; need tr
command -v perl >/dev/null 2>&1 || PERL_MISSING=1

# -------- Sanitizers --------

# Strip ASCII control chars (<= 0x1F) except LF; removes CR too.
_strip_ascii_ctrl() {
  printf '%s' "$1" \
  | tr -d '\001\002\003\004\005\006\007\010\011\013\014\015\016\017\020\021\022\023\024\025\026\027\030\031\032\033\034\035\036\037'
}

# Unicode clean: normalize, drop ALL format chars (\p{Cf}), drop bidi/ZW*, trim Unicode spaces.
_unicode_clean() {
  if [[ -n "${PERL_MISSING:-}" ]]; then
    perl -CSDA -pe '
      s/[\x{200B}-\x{200F}\x{202A}-\x{202E}\x{2066}-\x{2069}\x{FEFF}]//g;
      s/\p{Space}+\z//; s/\A\p{Space}+//;
    ' 2>/dev/null || cat
  else
    perl -CSDA -MUnicode::Normalize=NFKC -pe '
      $_ = NFKC($_);
      s/\p{Cf}//g;
      s/\p{Space}+\z//; s/\A\p{Space}+//;
    '
  fi
}

sanitize_path() {
  local s="$1"
  s="$(_strip_ascii_ctrl "$s")"
  s="$(_unicode_clean <<<"$s")"
  printf '%s' "$s"
}

log_debug() {
  [[ "$DEBUG" -eq 1 ]] || return 0
  local label="$1" val="$2"
  printf 'DBG %s: %q\n' "$label" "$val" >&2
  printf '%s' "$val" | od -An -tx1 | sed 's/^/    hex: /' >&2
}

# Optional: rename files on disk to cleaned names
rename_clean_if_needed() {
  local raw="$1" clean
  clean="$(sanitize_path "$raw")"
  [[ "$raw" == "$clean" ]] && return 0
  if [[ "$RENAME_CLEAN" -eq 1 ]]; then
    if [[ -e "$clean" && "$raw" != "$clean" ]]; then
      echo "Warning: target exists, skipping rename: $clean" >&2
      return 0
    fi
    echo "Renaming: $raw -> $clean"
    mv -- "$raw" "$clean"
  fi
}

# -------- Core work --------

has_video_stream() {
  # NOTE: ffprobe has NO -nostdin option. We only redirect stdin to /dev/null.
  ffprobe -v error -select_streams v:0 \
    -show_entries stream=codec_type -of csv=p=0 -- "$1" </dev/null 2>/dev/null \
  | grep -qi '^video$'
}

get_duration() {
  ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 -- "$1" </dev/null 2>/dev/null \
  || true
}

generate_thumbnail() {
  local RAW_FILE="$1" OUT_DIR="$2"
  local FILE BASENAME STEM OUT_JPG DURATION RAND_TIME

  rename_clean_if_needed "$RAW_FILE"

  FILE="$(sanitize_path "$RAW_FILE")"
  [[ -e "$FILE" ]] || [[ ! -e "$RAW_FILE" ]] || FILE="$RAW_FILE"
  if [[ ! -e "$FILE" ]]; then
    log_debug "MISSING" "$RAW_FILE"
    echo "Warning: not found: $RAW_FILE" >&2
    return
  fi

  log_debug "FILE" "$FILE"

  BASENAME="$(basename -- "$FILE")"
  STEM="${BASENAME%.*}"
  OUT_JPG="$OUT_DIR/$STEM.jpg"
  mkdir -p -- "$OUT_DIR"

  if [[ -e "$OUT_JPG" && "$FORCE" -eq 0 ]]; then
    echo "Skip (exists): $OUT_JPG"
    return
  fi

  # Must have a video stream (avoid spinning wheels on non-video).
  if ! has_video_stream "$FILE"; then
    echo "Skip (no video streams): $FILE" >&2
    return
  fi

  local VF_ARGS=()
  [[ -n "$THUMB_WIDTH" ]] && VF_ARGS=(-vf "scale=${THUMB_WIDTH}:-1")

  echo "Generating thumbnail for: $FILE"

  # A) No-seek representative frame first (most robust)
  if ffmpeg -nostdin -v error -i "$FILE" -map 0:v:0 \
        -vf "thumbnail=500${THUMB_WIDTH:+,scale=${THUMB_WIDTH}:-1}" \
        -frames:v 1 -q:v 2 -y -- "$OUT_JPG" </dev/null; then
    echo "✅ $OUT_JPG"; return
  fi

  # Duration (may be N/A/0; we’ll still fallback)
  DURATION="$(get_duration "$FILE")"
  if [[ -z "$DURATION" || "$DURATION" == "N/A" || "$DURATION" == "0" ]]; then
    RAND_TIME="1.000"
  else
    RAND_TIME="$(awk -v d="$DURATION" 'BEGIN { srand(); if (d<=0.5) print 0.0; else printf "%.3f", 0.25 + rand()*(d-0.5) }')"
  fi

  # B) Input-side random seek (fast)
  if ffmpeg -nostdin -v error -ss "$RAND_TIME" -i "$FILE" -map 0:v:0 \
        -frames:v 1 -q:v 2 "${VF_ARGS[@]}" -y -- "$OUT_JPG" </dev/null; then
    echo "✅ $OUT_JPG"; return
  fi

  # C) Output-side seek (more tolerant)
  if ffmpeg -nostdin -v error -i "$FILE" -ss "$RAND_TIME" -map 0:v:0 \
        -frames:v 1 -q:v 2 "${VF_ARGS[@]}" -y -- "$OUT_JPG" </dev/null; then
    echo "✅ $OUT_JPG"; return
  fi

  # D) Remux (fix timestamps/moov/PTS), then thumbnail
  local FIXED="${OUT_DIR}/${STEM}.fixed.mp4"
  if ffmpeg -nostdin -v error -i "$FILE" -map 0 -c copy \
        -movflags +faststart -fflags +genpts -y -- "$FIXED" </dev/null; then
    if ffmpeg -nostdin -v error -i "$FIXED" -map 0:v:0 \
          -vf "thumbnail=500${THUMB_WIDTH:+,scale=${THUMB_WIDTH}:-1}" \
          -frames:v 1 -q:v 2 -y -- "$OUT_JPG" </dev/null; then
      echo "✅ $OUT_JPG (via remux)"; return
    fi
  fi

  echo "❌ Failed after all fallbacks: $FILE" >&2
}

process_directory() {
  local DIR="$1" OUT_DIR="$2"
  local any=0
  # Don’t feed images back into the loop; enumerate files/symlinks, skip jpg/png/webp/gif.
  while IFS= read -r -d '' f; do
    any=1
    generate_thumbnail "$f" "$OUT_DIR"
  done < <(
    find "$DIR" -maxdepth 1 \( -type f -o -type l \) \
      -not -iregex '.*\.\(jpe\?g\|png\|gif\|webp\)$' \
      -print0
  )

  [[ "$any" -eq 0 ]] && echo "Note: No files found in $DIR"
}

process_file() {
  local f="$1" OUT_DIR="$2"
  generate_thumbnail "$f" "$OUT_DIR"
}

# -------- CLI --------

if [[ $# -lt 1 ]]; then
  cat <<EOF
Usage:
  $0 file.mp4 [output_dir]
  $0 -d /path/to/dir [output_dir]
Options:
  -f, --force        Overwrite existing JPGs (default)
      --no-force     Skip existing JPGs
      --debug        Show hidden chars/hex for processed paths
      --rename-clean Normalize + trim filenames on disk before processing
EOF
  exit 1
fi

MODE="auto"; INPUT=""; OUT_DIR=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d) MODE="dir"; INPUT="${2:-}"; shift 2 ;;
    -f|--force) FORCE=1; shift ;;
    --no-force) FORCE=0; shift ;;
    --debug) DEBUG=1; shift ;;
    --rename-clean) RENAME_CLEAN=1; shift ;;
    --) shift; break ;;
    -*)
      printf "Unknown option: %s\n" "$1" >&2; exit 1 ;;
    *)
      if [[ -z "$INPUT" ]]; then INPUT="$1"; shift
      else OUT_DIR="$1"; shift
      fi
      ;;
  esac
done

if [[ "$MODE" == "dir" ]]; then
  [[ -z "${OUT_DIR:-}" ]] && OUT_DIR="$INPUT"     # save next to files by default
  [[ -d "$INPUT" ]] || { printf "Error: %q is not a directory.\n" "$INPUT" >&2; exit 1; }
  process_directory "$INPUT" "$OUT_DIR"
else
  [[ -e "$INPUT" ]] || { printf "Error: %q not found.\n" "$INPUT" >&2; exit 1; }
  if [[ -d "$INPUT" ]]; then
    [[ -z "${OUT_DIR:-}" ]] && OUT_DIR="$INPUT"
    process_directory "$INPUT" "$OUT_DIR"
  else
    [[ -z "${OUT_DIR:-}" ]] && OUT_DIR="$(dirname -- "$INPUT")"
    process_file "$INPUT" "$OUT_DIR"
  fi
fi

