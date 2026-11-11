#!/bin/sh
# two stacked kittys beside emacs on 2:org. the later window lands on the right
# and kitty maps well before doom does, so each waits for the one before (30s at most)
wait_for() {
    for _ in $(seq 150); do
        swaymsg -q "[app_id=\"^$1\$\"] nop" && return
        sleep 0.2
    done
    notify-send -a 'org workspace' "Window did not appear: $1"
    return 1
}

wait_for emacs || exit 1
kitty --class org-term --directory ~/org &
wait_for org-term || exit 1
exec kitty --class org-term-home --directory ~
