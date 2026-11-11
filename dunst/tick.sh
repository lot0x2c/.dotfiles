#!/bin/sh
# teal at every whole 10 minutes: :00, :10, :20 ...
while sleep $((600 - $(date +%s) % 600)); do
    # sway is gone: don't outlive the session and double up on the next login
    [ -z "$SWAYSOCK" ] || [ -S "$SWAYSOCK" ] || exit 0
    notify-send -c reminder -t 8000 -h string:x-dunst-stack-tag:tick "$(date +%H:%M)" "10 minutes gone"
done
