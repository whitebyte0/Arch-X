#!/bin/bash
# Dynamically assign up to 10 workspaces across monitors

# Prompt monitor setup if multiple monitors and no config yet
LOCAL_DIR="$HOME/.config/hypr-local"
mkdir -p "$LOCAL_DIR"
mapfile -t monitors < <(hyprctl monitors -j | jq -r '.[].name')
count=${#monitors[@]}

if [ "$count" -gt 1 ] && [ ! -f "$LOCAL_DIR/monitors.conf" ]; then
    notify-send -u normal "Arch-X" "Multiple monitors detected — run setup-monitors.sh to arrange them" 2>/dev/null
fi

per_monitor=$((10 / count))
remainder=$((10 % count))

ws=1
for i in "${!monitors[@]}"; do
    # Give extra workspace to first monitors if remainder exists
    n=$per_monitor
    if [ "$i" -lt "$remainder" ]; then
        n=$((n + 1))
    fi
    for j in $(seq 1 $n); do
        hyprctl keyword workspace "$ws, monitor:${monitors[$i]}" 2>/dev/null
        ws=$((ws + 1))
    done
done

# Set each monitor beyond the first to its first workspace
ws=$((per_monitor + (0 < remainder ? 1 : 0) + 1))
for i in $(seq 1 $((count - 1))); do
    hyprctl dispatch focusmonitor "${monitors[$i]}"
    hyprctl dispatch workspace "$ws"
    extra=$((i < remainder ? 1 : 0))
    ws=$((ws + per_monitor + extra))
done

# Return focus to first monitor
hyprctl dispatch focusmonitor "${monitors[0]}"
