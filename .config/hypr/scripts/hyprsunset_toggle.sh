#!/bin/bash

# Toggle hyprsunset service on/off (supports --on and --off args)

case "$1" in
    --on)
        systemctl --user start hyprsunset
        notify-send "Hyprsunset" "Enabled" -t 2000
        ;;
    --off)
        systemctl --user stop hyprsunset
        notify-send "Hyprsunset" "Disabled" -t 2000
        ;;
    *)
        # Toggle if no argument provided
        if systemctl --user is-active --quiet hyprsunset; then
            systemctl --user stop hyprsunset
            notify-send "Hyprsunset" "Disabled" -t 2000
        else
            systemctl --user start hyprsunset
            notify-send "Hyprsunset" "Enabled" -t 2000
        fi
        ;;
esac
