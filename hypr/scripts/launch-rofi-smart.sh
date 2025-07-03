#!/usr/bin/env bash

# Script to launch Rofi in "smart" mode, capture selection, and act on it.

# Define the path to the Rofi script that generates the options
ROFI_SMART_SCRIPT="$HOME/.config/rofi/scripts/rofi-smart.sh"
# Define the path to the script that fetches default weather (used by "Weather" option)
ROFI_WEATHER_SCRIPT="$HOME/.config/rofi/scripts/rofi-weather.sh"

# Check dependencies
if ! command -v rofi &> /dev/null; then echo "Error: rofi not found!"; exit 1; fi
if ! command -v notify-send &> /dev/null; then echo "Error: notify-send not found! (Install libnotify)"; exit 1; fi
if ! command -v wl-copy &> /dev/null; then echo "Error: wl-copy not found! (Install wl-clipboard)"; exit 1; fi
if [ ! -x "$ROFI_SMART_SCRIPT" ]; then echo "Error: $ROFI_SMART_SCRIPT not found or not executable!"; exit 1; fi
if [ ! -x "$ROFI_WEATHER_SCRIPT" ]; then echo "Error: $ROFI_WEATHER_SCRIPT not found or not executable!"; exit 1; fi


# Launch Rofi using the smart script, capture the selection
SELECTION=$(rofi -show smart \
               -modi "smart:${ROFI_SMART_SCRIPT}" \
               -theme-str 'window {width: 50%;}' \
               -dmenu -p "Smart:")
               # Add any other Rofi flags you normally use here

# Exit if Rofi was cancelled (empty selection)
if [ -z "$SELECTION" ]; then
    exit 0
fi

# Act based on the selection
case "$SELECTION" in
    "Apps")
        rofi -show drun -display-drun "Apps"
        ;;
    "Weather")
        WEATHER_DATA=$("$ROFI_WEATHER_SCRIPT")
        notify-send --app-name="RofiSmart" "Weather" "$WEATHER_DATA"
        ;;
    *)
        # Assume it's a weather forecast line selected
        wl-copy "$SELECTION" && notify-send --app-name="RofiSmart" "Weather Copied" "$SELECTION"
        ;;
esac

exit 0
