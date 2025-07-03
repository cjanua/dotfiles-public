#!/bin/bash

# Function to check if pipes.sh is already running
is_pipes_running() {
    pgrep -f "pipes.sh" > /dev/null
}

# Function to start pipes.sh
start_pipes() {
    if ! is_pipes_running; then
        export ACTIVE_WINDOW=$(hyprctl activewindow -j | jq -r '.address')
        pipes.sh -f &
        PIPES_PID=$!
        sleep 0.5
        hyprctl dispatch focuswindow "title:^(pipes.sh)$"
    fi
}

# Function to stop pipes.sh
stop_pipes() {
    if is_pipes_running; then
        pkill -f "pipes.sh"
        if [ ! -z "$ACTIVE_WINDOW" ]; then
            hyprctl dispatch focuswindow "address:$ACTIVE_WINDOW"
        fi
    fi
}

# Check if Hyprland is running
if [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    echo "Error: Hyprland is not running or HYPRLAND_INSTANCE_SIGNATURE is not set"
    exit 1
fi

SOCKET_PATH="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

if [ ! -S "$SOCKET_PATH" ]; then
    echo "Error: Socket $SOCKET_PATH does not exist"
    echo "Available sockets in $XDG_RUNTIME_DIR/hypr/:"
    ls -l "$XDG_RUNTIME_DIR/hypr/"
    exit 1
fi

# Set up event monitoring
socat - "UNIX-CONNECT:$SOCKET_PATH" | while read -r line; do
    case ${line%>>*} in
        *"keyboard"* | *"mousemove"* | *"mousedown"*)
            stop_pipes
            ;;
    esac
done &

# Main loop to check for inactivity
while true; do
    LAST_INPUT=$(hyprctl activewindow -j | jq -r '.last_input')
    CURRENT_TIME=$(date +%s%N)
    IDLE_TIME=$(( ($CURRENT_TIME - $LAST_INPUT) / 1000000 ))

    if [ $IDLE_TIME -gt 30000 ]; then
        start_pipes
    fi

    sleep 1
done