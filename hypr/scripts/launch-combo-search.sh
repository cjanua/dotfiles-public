#!/usr/bin/env bash

# Launcher for Rofi combi mode (Apps + Web Search Fallback) - WITH DEBUGGING

LOG_FILE="/tmp/rofi_combo.log"
ROFI_WEBSCRIPT="$HOME/.config/rofi/scripts/rofi-websearch-option.sh"
SEPARATOR=" ::: "
ACTION_TEXT="Search Web"

# Clear log file for new run
echo "--- Starting launch-combo-search.sh at $(date) ---" > "$LOG_FILE"
echo "Webscript path: $ROFI_WEBSCRIPT" >> "$LOG_FILE"
echo "Separator: '$SEPARATOR'" >> "$LOG_FILE"
echo "Action Text: '$ACTION_TEXT'" >> "$LOG_FILE"

# Check if webscript exists and is executable
if [ ! -x "$ROFI_WEBSCRIPT" ]; then
    echo "ERROR: Webscript $ROFI_WEBSCRIPT not found or not executable!" >> "$LOG_FILE"
    notify-send "Rofi Error" "Webscript $ROFI_WEBSCRIPT not found or not executable!"
    exit 1
fi

# URL encoding function
urlencode() {
    # ... (same urlencode function as before) ...
    local string="${1}"; local strlen=${#string}; local encoded=""; local pos c o
    for (( pos=0 ; pos<strlen ; pos++ )); do c=${string:$pos:1}; case "$c" in [-_. ~a-zA-Z0-9] ) o="${c}" ;; *) printf -v o '%%%02x' "'$c"; esac; encoded+="${o}"; done; echo "${encoded}"
}

# Construct the Rofi command
ROFI_CMD="rofi -show combi \
               -modi \"drun,websearch:${ROFI_WEBSCRIPT}\" \
               -dmenu \
               -i \
               -p \"Search Apps / Web:\" \
               -markup-rows \
               -format 's'"

echo "Running Rofi command: $ROFI_CMD" >> "$LOG_FILE"

# Run Rofi and capture selection and exit status
SELECTION=$(eval "$ROFI_CMD")
ROFI_EXIT_STATUS=$?

echo "Rofi exit status: $ROFI_EXIT_STATUS" >> "$LOG_FILE"
echo "Raw selection: [$SELECTION]" >> "$LOG_FILE"

# Exit if Rofi was cancelled (non-zero exit status often indicates Esc)
# Or if selection is empty (might happen depending on Rofi version/config)
if [ $ROFI_EXIT_STATUS -ne 0 ] || [ -z "$SELECTION" ]; then
    echo "Rofi cancelled or selection empty. Exiting." >> "$LOG_FILE"
    exit 0
fi

# Act based on the selection
echo "Processing selection..." >> "$LOG_FILE"
if [[ "$SELECTION" == *"$SEPARATOR$ACTION_TEXT" ]]; then
    # Web Search Action
    SEARCH_TERM="${SELECTION%$SEPARATOR*}"
    echo "Action: Web Search for '$SEARCH_TERM'" >> "$LOG_FILE"
    ENCODED_TERM=$(urlencode "$SEARCH_TERM")
    XDG_CMD="xdg-open \"https://duckduckgo.com/?q=${ENCODED_TERM}\""
    echo "Executing: $XDG_CMD" >> "$LOG_FILE"
    eval "$XDG_CMD" &
else
    # Application Launch Attempt
    echo "Action: Attempting to launch app '$SELECTION'" >> "$LOG_FILE"
    APP_CMD="nohup \"$SELECTION\" > /dev/null 2>&1 &"
    echo "Executing: $APP_CMD" >> "$LOG_FILE"
    # Using exec directly within the subshell from nohup might be slightly better
    (nohup "$SELECTION" >/dev/null 2>&1 &)
    # Alternatively, try gtk-launch if it seems appropriate (less reliable detection here)
    # if [[ "$SELECTION" == *.desktop ]]; then
    #   echo "Trying gtk-launch $SELECTION" >> "$LOG_FILE"
    #   (gtk-launch "$SELECTION" &)
    # else
       # (nohup "$SELECTION" >/dev/null 2>&1 &)
    # fi
fi

echo "--- Script finished ---" >> "$LOG_FILE"
exit 0
