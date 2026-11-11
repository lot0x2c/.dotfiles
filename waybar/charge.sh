#!/bin/sh
# the charge limit, or with "toggle" flip upower's threshold. waybar is
# signalled after: rerunning on the click would read the limit before upower
# wrote it

limit=/sys/class/power_supply/BAT0/charge_control_end_threshold
# no charge limit on this battery: an empty module, not an error every run
[ -r "$limit" ] || exit 0
read -r n < "$limit"
if [ "${1-}" = toggle ]; then
    enable=true
    [ "$n" -lt 100 ] && enable=false
    busctl --system call org.freedesktop.UPower \
        /org/freedesktop/UPower/devices/battery_BAT0 \
        org.freedesktop.UPower.Device EnableChargeThreshold b "$enable" \
        >/dev/null && pkill -RTMIN+8 waybar
else
    echo "$n"
fi
