#!/bin/bash

for i in {1..9}; do
  sketchybar --add item "space.$i" left \
             --set "space.$i" \
                   icon="$i" \
                   label.drawing=off \
                   icon.padding_left=7 \
                   icon.padding_right=7 \
                   background.height=24 \
                   background.corner_radius=6 \
                   click_script="if command -v yabai >/dev/null 2>&1; then yabai -m space --focus $i; elif command -v aerospace >/dev/null 2>&1; then aerospace workspace $i; fi" \
                   script="$PLUGIN_DIR/spaces.sh" \
                   update_freq=1
done

sketchybar --add item spaces.chevron left \
           --set spaces.chevron \
                 icon="›" \
                 icon.font="SF Pro:Bold:19" \
                 label.drawing=off \
                 icon.padding_left=6 \
                 icon.padding_right=9
