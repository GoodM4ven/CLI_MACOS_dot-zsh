#!/bin/bash
sources="$(defaults read com.apple.HIToolbox AppleSelectedInputSources 2>/dev/null || true)"
if printf '%s' "$sources" | grep -Eqi 'Arabic|Arabic - PC|com\.apple\.keylayout\.Arabic'; then
  indicator="ا"
else
  indicator="A"
fi
sketchybar --set input_source label="$indicator"
