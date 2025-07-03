#!/usr/bin/env bash
SEPARATOR=" ::: "
ACTION_TEXT="Search Web"
if [ -n "$@" ]; then
    echo -n "$@"
    echo -n "$SEPARATOR"
    echo "$ACTION_TEXT"
fi
exit 0
