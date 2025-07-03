#!/usr/bin/env bash

# Helper script called by Rofi keybinding to handle selection

SEPARATOR=" - "
ACTION_TEXT="Search Web"
SELECTION="$@" # Rofi passes the selected line as arguments

# URL encoding function
urlencode() {
    local string="${1}"; local strlen=${#string}; local encoded=""; local pos c o
    for (( pos=0 ; pos<strlen ; pos++ )); do c=${string:$pos:1}; case "$c" in [-_. ~a-zA-Z0-9] ) o="${c}" ;; *) printf -v o '%%%02x' "'$c"; esac; encoded+="${o}"; done; echo "${encoded}"
}

# Check if the selection is the "Search Web" action
if [[ "$SELECTION" == *"$SEPARATOR$ACTION_TEXT" ]]; then
    # Extract the search term
    SEARCH_TERM="${SELECTION%$SEPARATOR*}"
    ENCODED_TERM=$(urlencode "$SEARCH_TERM")
    # Execute web search using xdg-open
    xdg-open "https://duckduckgo.com/?q=${ENCODED_TERM}" &
    # Exit successfully after launching browser
    exit 0
else
    # If it's not the web search option, exit with a non-zero code
    # to signal Rofi to perform its default action (launching the app from drun)
    exit 1
fi
