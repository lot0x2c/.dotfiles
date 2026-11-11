#!/usr/bin/env bash
# a region, or with "screen" the focused output. saved to ~/images/ss and copied
set -eu

if [ "${1-}" = screen ]; then
    area=(-o "$(swaymsg -t get_outputs | jq -r '.[] | select(.focused).name')")
else
    area=(-g "$(slurp)") || exit 0
fi
shots="$HOME/images/ss"
mkdir -p "$shots"
file=$(mktemp "$shots/$(date +%Y%m%d-%H%M%S)-XXXXXX.png")

if ! grim "${area[@]}" "$file"; then
    rm -f "$file"
    notify-send -a screenshot 'screenshot failed'
    exit 1
fi
if wl-copy --type image/png <"$file"; then
    notify-send -a screenshot -i "$file" 'screenshot' 'copied · ~/images/ss'
else
    notify-send -a screenshot -i "$file" 'screenshot, not copied' 'saved in ~/images/ss'
fi
