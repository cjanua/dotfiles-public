#!/usr/bin/env bash
SEPARATOR=" ::: "
ACTION_TEXT="Search Web"
SELECTION="$@"
urlencode() {
    local string="${1}"; local strlen=${#string}; local encoded=""; local pos c o
    for (( pos=0 ; pos<strlen ; pos++ )); do c=${string:$pos:1}; case "$c" in [-_. ~a-zA-Z0-9] ) o="${c}" ;; *) printf -v o '%%%02x' "'$c"; esac; encoded+="${o}"; done; echo "${encoded}"
}
if [[ "$SELECTION" == *"$SEPARATOR$ACTION_TEXT" ]]; then
    SEARCH_TERM="${SELECTION%$SEPARATOR*}"
    ENCODED_TERM=$(urlencode "$SEARCH_TERM")
    xdg-open "https://duckduckgo.com/?q=${ENCODED_TERM}" &
    exit 0 # Success
else
    exit 0 # Do nothing if it wasn't the web search option
fi
