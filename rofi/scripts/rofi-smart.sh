#!/usr/bin/env bash

# Launcher Script v2:
# 1. Get input via Rofi dmenu.
# 2. Try fetching weather for the input.
# 3. If weather fetch succeeds, show notification.
# 4. Otherwise, launch Rofi app search (drun) with the input as filter.

DEFAULT_LOCATION="University of Central Florida" # Used only if needed, wttr.in auto-detects too

# Check dependencies
if ! command -v rofi &> /dev/null; then echo "Error: rofi not found!"; exit 1; fi
if ! command -v curl &> /dev/null; then echo "Error: curl not found!"; exit 1; fi
if ! command -v notify-send &> /dev/null; then echo "Error: notify-send not found! (Install libnotify)"; exit 1; fi

# 1. Get input using Rofi dmenu
QUERY=$(rofi -dmenu -p "Smart:")

# Exit if Rofi was cancelled (empty query) - fallback to Apps in this case too
# if [ -z "$QUERY" ]; then
#     rofi -show drun -display-drun "Apps" # Or just exit 0 if you want Esc to do nothing
#     exit 0
# fi

# 2. Try fetching weather if QUERY is not empty
WEATHER_INFO=""
FETCH_SUCCESS=false
if [ -n "$QUERY" ]; then
    # Function to URL encode (same as previous script)
    urlencode() {
        local string="${1}"; local strlen=${#string}; local encoded=""; local pos c o
        for (( pos=0 ; pos<strlen ; pos++ )); do c=${string:$pos:1}; case "$c" in [-_. ~a-zA-Z0-9] ) o="${c}" ;; *) printf -v o '%%%02x' "'$c"; esac; encoded+="${o}"; done; echo "${encoded}"
    }
    ENCODED_LOCATION=$(urlencode "$QUERY")
    FORMAT_STRING="%l: %c %t, Feels %f, Wind %w"
    ENCODED_FORMAT_STRING=$(echo "$FORMAT_STRING" | sed 's/ /%20/g')
    URL="wttr.in/${ENCODED_LOCATION}?format=${ENCODED_FORMAT_STRING}"

    # Attempt curl
    WEATHER_OUTPUT=$(curl --connect-timeout 5 --fail -s "$URL")
    CURL_EXIT_CODE=$?

    # Check for success
    if [ $CURL_EXIT_CODE -eq 0 ] && [ -n "$WEATHER_OUTPUT" ]; then
        WEATHER_INFO="$WEATHER_OUTPUT"
        FETCH_SUCCESS=true
    fi
fi

# 3. If weather fetch succeeded, show notification
if [ "$FETCH_SUCCESS" = true ]; then
    notify-send --app-name="RofiSmart" "Weather: $QUERY" "$WEATHER_INFO"
else
# 4. Otherwise, launch Rofi app search (drun) with the input as filter
    rofi -show drun -filter "$QUERY" -display-drun "Apps"
fi

exit 0
