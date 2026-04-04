#!/bin/bash
# Center module: shows notification text when active, clock otherwise.
# Refreshed instantly via SIGRTMIN+8 from AGS.

NOTIF_FILE="$HOME/.config/arch-x/notification-current.json"

if [[ -s "$NOTIF_FILE" ]]; then
    summary=$(jq -r '.summary // empty' "$NOTIF_FILE" 2>/dev/null)
    body=$(jq -r '.body // empty' "$NOTIF_FILE" 2>/dev/null)
    urgency=$(jq -r '.urgency // "normal"' "$NOTIF_FILE" 2>/dev/null)

    if [[ -n "$summary" ]]; then
        text="$summary"
        [[ -n "$body" ]] && text="$summary  $body"
        # Truncate if too long
        if (( ${#text} > 80 )); then
            text="${text:0:77}..."
        fi
        # Escape quotes for JSON
        text="${text//\"/\\\"}"
        tooltip="${summary//\"/\\\"}\\n${body//\"/\\\"}"
        echo "{\"text\": \"$text\", \"class\": \"notif-$urgency\", \"tooltip\": \"$tooltip\"}"
        exit 0
    fi
fi

# Fallback: clock
echo "{\"text\": \"󰥔 $(date +'%H:%M')\", \"class\": \"clock\", \"tooltip\": \"$(date +'%A, %d %B %Y  %H:%M')\"}"
