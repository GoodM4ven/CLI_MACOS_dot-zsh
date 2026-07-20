#!/bin/bash

common=(
  icon.font="SF Pro:Semibold:12"
  label.font="SF Pro:Semibold:12"
  background.drawing=on
  background.color=0x663B4252
  background.corner_radius=7
  background.height=25
  padding_left=2
  padding_right=2
)

sketchybar --add item cpu right \
           --set cpu "${common[@]}" \
                 icon="CPU" \
                 icon.padding_left=7 \
                 icon.padding_right=4 \
                 label.padding_left=0 \
                 label.padding_right=7 \
                 script="$PLUGIN_DIR/cpu.sh" \
                 update_freq=2

sketchybar --add item ram right \
           --set ram "${common[@]}" \
                 icon="RAM" \
                 icon.padding_left=7 \
                 icon.padding_right=4 \
                 label.padding_left=0 \
                 label.padding_right=7 \
                 script="$PLUGIN_DIR/ram.sh" \
                 update_freq=2

sketchybar --add item battery right \
           --set battery "${common[@]}" \
                 icon.font="SF Pro:Bold:14" \
                 icon.padding_left=7 \
                 icon.padding_right=5 \
                 label.padding_left=0 \
                 label.padding_right=7 \
                 script="$PLUGIN_DIR/battery.sh" \
                 update_freq=15 \
           --subscribe battery power_source_change

sketchybar --add item clock right \
           --set clock \
                 icon="◷" \
                 icon.font="SF Pro:Bold:19" \
                 icon.padding_left=7 \
                 icon.padding_right=5 \
                 label.font="SF Pro:Semibold:13" \
                 label.padding_left=0 \
                 label.padding_right=8 \
                 background.drawing=off \
                 script="$PLUGIN_DIR/clock.sh" \
                 update_freq=1
