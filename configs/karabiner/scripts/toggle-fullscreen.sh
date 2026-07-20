#!/bin/bash
osascript <<'EOF'
tell application "System Events"
    set frontApp to first application process whose frontmost is true
    if (count of windows of frontApp) > 0 then
        set win to window 1 of frontApp
        set isFull to value of attribute "AXFullScreen" of win
        set value of attribute "AXFullScreen" of win to not isFull
    end if
end tell
EOF
