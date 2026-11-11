#!/bin/sh
# reminders at 90, 80 ... 30%. poweralertd does the low and critical ones
# starts from the current level, so plugging in and out starts a new cycle
bat=/sys/class/power_supply/BAT0
[ -r "$bat/capacity" ] || exit 1 # no battery
read -r previous < "$bat/capacity"
while sleep 30; do
    # sway is gone: don't outlive the session and double up on the next login
    [ -z "$SWAYSOCK" ] || [ -S "$SWAYSOCK" ] || exit 0
    # a failed read (the battery re-registering) skips a round, it doesn't end the reminders
    read -r status < "$bat/status" || continue
    read -r n < "$bat/capacity" || continue
    case $n in '' | *[!0-9]*) continue ;; esac
    case $previous in '' | *[!0-9]*) previous=$n ;; esac
    if [ "$status" = Discharging ] && [ "$n" -gt 20 ]; then
        for threshold in 90 80 70 60 50 40 30; do
            if [ "$previous" -gt "$threshold" ] && [ "$n" -le "$threshold" ]; then
                notify-send -c reminder -h string:x-dunst-stack-tag:battery "battery $n%"
                break # one notification, even if it crossed several
            fi
        done
    fi
    previous=$n
done
