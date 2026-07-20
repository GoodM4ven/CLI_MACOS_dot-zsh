#!/bin/bash

sketchybar --add item workspace_apps left \
           --set workspace_apps \
                 icon.drawing=off \
                 label.font="SF Pro:Semibold:13" \
                 label.max_chars=110 \
                 label.padding_left=2 \
                 label.padding_right=8 \
                 script="$PLUGIN_DIR/workspace_apps.sh" \
                 update_freq=1 \
           --subscribe workspace_apps \
                 front_app_switched \
                 space_change \
                 space_windows_change \
                 display_change
