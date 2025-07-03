#!/usr/bin/env bash

# Rofi script for checking weather using wttr.in (Revised v6)
# Encodes location, fetches and displays weather immediately.

DEFAULT_LOCATION="University Park, FL" # Or leave empty: "" for auto-detect
PROMPT="Weather Location" # Prompt text (currently unused as it fetches immediately)

# Function to URL encode a string using basic sed (handles common chars like space, comma)
# More robust encoding might use `jq` or `python` if available and needed.
urlencode() {
    local string="${1}"
    local strlen=${#string}
    local encoded=""
    local pos c o

    for (( pos=0 ; pos<strlen ; pos++ )); do
        c=${string:$pos:1}
        case "$c" in
            [-_.~a-zA-Z0-9] ) o="${c}" ;;
            * )               printf -v o '%%%02x' "'$c"
        esac
        encoded+="${o}"
    done
    echo "${encoded}"
}


if ! command -v curl &> /dev/null; then
    echo "Error: curl is not installed."
    exit 1
fi

# Determine the location (Always use default in this version)
LOCATION="$DEFAULT_LOCATION"

# --- URL Encode the Location ---
ENCODED_LOCATION=$(urlencode "$LOCATION")

# Format string for curl
FORMAT_STRING="%l: %c %t, Feels %f, Wind %w"
# URL encode the format string (simple space encoding needed here)
ENCODED_FORMAT_STRING=$(echo "$FORMAT_STRING" | sed 's/ /%20/g')

# Construct the URL (Handle empty location for auto-detect)
# Use the URL-encoded location
if [ -z "$ENCODED_LOCATION" ]; then
    # If default location was empty, query without location path
    URL="wttr.in/?format=${ENCODED_FORMAT_STRING}"
else
    URL="wttr.in/${ENCODED_LOCATION}?format=${ENCODED_FORMAT_STRING}"
fi

# --- Debug: Echo the final URL ---
# echo "Debug URL: $URL" > /tmp/rofi_weather_debug.log

# Store curl output and exit code
WEATHER_INFO=$(curl --fail -s "$URL")
CURL_EXIT_CODE=$?

# --- Debug: Echo curl result ---
# echo "Debug Curl Exit: $CURL_EXIT_CODE" >> /tmp/rofi_weather_debug.log
# echo "Debug Curl Output: $WEATHER_INFO" >> /tmp/rofi_weather_debug.log


# Check curl exit code AND if output is non-empty
if [ $CURL_EXIT_CODE -eq 0 ] && [ -n "$WEATHER_INFO" ]; then
    echo "$WEATHER_INFO"
elif [ $CURL_EXIT_CODE -ne 0 ]; then
    case $CURL_EXIT_CODE in
        3) echo "Error: URL Malformed (Code: 3). Issue likely in script's URL construction." ;; # Changed msg slightly
        6) echo "Error: Couldn't resolve host (Code: 6). Check DNS/Network." ;;
        7) echo "Error: Failed to connect to host (Code: 7). Check Network/Firewall." ;;
        22) echo "Error: HTTP error (Code: 22). Location likely invalid for wttr.in?" ;;
        *) echo "Error: curl command failed (Code: $CURL_EXIT_CODE)." ;;
    esac
else
    echo "Error: Could not fetch weather for '$LOCATION'. Location invalid or wttr.in issue?"
fi

exit 0
