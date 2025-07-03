#!/usr/bin/env bash

# Launcher Script v3.1: Simplified - Use dmenu for input, then decide action.
# Corrected urlencode function.

LAUNCH_LOG_FILE="/tmp/rofi_launcher.log" # Keep logging for now
DEFAULT_LOCATION="University Park, FL"

# Clear log file
echo "--- Starting launch-smart-agent.sh (v3.1) at $(date) ---" > "$LAUNCH_LOG_FILE"

# Check dependencies
if ! command -v rofi &> /dev/null; then echo "Error: rofi not found!" >> "$LAUNCH_LOG_FILE"; exit 1; fi
if ! command -v curl &> /dev/null; then echo "Error: curl not found!" >> "$LAUNCH_LOG_FILE"; exit 1; fi
if ! command -v notify-send &> /dev/null; then echo "Error: notify-send not found! (Install libnotify)" >> "$LAUNCH_LOG_FILE"; exit 1; fi
if ! command -v xdg-open &> /dev/null; then echo "Error: xdg-open not found! (Install xdg-utils)" >> "$LAUNCH_LOG_FILE"; exit 1; fi


# URL encoding function (Corrected v3 - NO SPACE in case pattern)
urlencode() {
    local string="${1}"
    local strlen=${#string}
    local encoded=""
    local pos c o

    for (( pos=0 ; pos<strlen ; pos++ )); do
        c=${string:$pos:1}
        # Match URL-safe characters: alphanumeric, hyphen, underscore, period, tilde
        # CORRECTED PATTERN BELOW (NO SPACE):
        case "$c" in
            [-_.~a-zA-Z0-9] )
                o="${c}" # Keep safe characters as-is
                ;;
            * )
                # Percent-encode everything else
                printf -v o '%%%02x' "'$c"
                ;;
        esac
        encoded+="${o}"
    done
    echo "${encoded}"
}

# --- Step 1: Get Input via Rofi dmenu ---
ROFI_CMD="rofi -dmenu -i -p \"Search Apps / Web:\""
echo "Running Rofi command: $ROFI_CMD" >> "$LAUNCH_LOG_FILE"
# Use simple command execution, avoid eval if not strictly needed
QUERY=$(rofi -dmenu -i -p "Search Apps / Web:")
ROFI_EXIT_STATUS=$?

echo "Rofi exit status: $ROFI_EXIT_STATUS" >> "$LAUNCH_LOG_FILE"
echo "Raw query: [$QUERY]" >> "$LAUNCH_LOG_FILE"

# Exit if Rofi was cancelled
if [ $ROFI_EXIT_STATUS -ne 0 ]; then
    echo "Rofi cancelled. Exiting." >> "$LAUNCH_LOG_FILE"
    exit 0
fi

# --- Step 2: Decide Action based on Query ---

WEATHER_INFO=""
FETCH_SUCCESS=false

# Try fetching weather ONLY if query is not empty
if [ -n "$QUERY" ]; then
    echo "Attempting weather fetch for query: [$QUERY]" >> "$LAUNCH_LOG_FILE"
    ENCODED_LOCATION=$(urlencode "$QUERY") # Use corrected function
    FORMAT_STRING="%l: %c %t, Feels %f, Wind %w"
    ENCODED_FORMAT_STRING=$(echo "$FORMAT_STRING" | sed 's/ /%20/g') # Encode format string spaces
    URL="wttr.in/${ENCODED_LOCATION}?format=${ENCODED_FORMAT_STRING}"
    echo "Weather URL: $URL" >> "$LAUNCH_LOG_FILE"

    WEATHER_OUTPUT=$(curl --connect-timeout 5 --fail -s "$URL")
    CURL_EXIT_CODE=$?

    if [ $CURL_EXIT_CODE -eq 0 ] && [ -n "$WEATHER_OUTPUT" ]; then
        WEATHER_INFO="$WEATHER_OUTPUT"
        FETCH_SUCCESS=true
        echo "Weather fetch SUCCESS" >> "$LAUNCH_LOG_FILE"
    else
        echo "Weather fetch FAILED (Curl Exit: $CURL_EXIT_CODE, Output Empty: $( [ -z "$WEATHER_OUTPUT" ] && echo true || echo false ))" >> "$LAUNCH_LOG_FILE"
    fi
fi

# --- Step 3: Execute Action ---

if [ "$FETCH_SUCCESS" = true ]; then
    # Action: Show Weather Notification
    echo "Action: Sending weather notification" >> "$LAUNCH_LOG_FILE"
    notify-send --app-name="RofiSmart" "Weather: $QUERY" "$WEATHER_INFO"
    # Optionally copy to clipboard
    # echo "$WEATHER_INFO" | wl-copy
else
    # Action: Fallback to App Search (drun mode)
    echo "Action: Launching Rofi drun with filter: [$QUERY]" >> "$LAUNCH_LOG_FILE"
    # Note: We run a *new* Rofi instance here in drun mode
    # Execute in background so this script can exit cleanly
    (rofi -show drun -filter "$QUERY" -display-drun "Apps" -i > /dev/null 2>&1 &)
fi

echo "--- Script finished ---" >> "$LAUNCH_LOG_FILE"
exit 0
