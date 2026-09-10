#!/usr/bin/env fish

pkill mpvpaper
# Give it a split second to breathe
sleep 0.2

# Run mpvpaper with correct argument separation
mpvpaper -l bottom -n 900 -o "--no-audio --shuffle --panscan=1.0 --hwdec=auto --profile=fast" eDP-1 "$HOME/Pictures/Videos/"
