#!/bin/sh
# waybar asks every second; skip python while nothing runs
if [ $# -eq 0 ] && ! grep -qs '"unit"' "$XDG_RUNTIME_DIR/timers/state.json"; then
    echo '{"text": "", "tooltip": "", "class": ""}'
    exit
fi
exec python3 "${0%/*}/timer.py" "$@"
