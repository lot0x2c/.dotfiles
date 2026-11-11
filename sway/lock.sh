#!/usr/bin/env bash
# -f forks once locked. a second lock just exits
exec swaylock -f \
    -i "$HOME/.config/sway/wxp.png" -s fill \
    --indicator-radius 90 --indicator-thickness 8 \
    --ring-color ed286f --ring-ver-color 00b9a3 --ring-wrong-color cb2762 \
    --key-hl-color feedf3 --bs-hl-color cb2762 \
    --line-color 00000000 --separator-color 00000000 \
    --inside-color 352930aa --text-color feedf3
