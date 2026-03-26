#!/usr/bin/env bash

BAT="/sys/class/power_supply/BAT0"

[[ ! -d "$BAT" ]] && echo '{"text": "", "class": "hidden"}' && exit 0

capacity=$(cat "$BAT/capacity")
status=$(cat "$BAT/status")

if [[ "$status" == "Charging" ]]; then
    icon="󱊥"
    class="charging"
elif [[ "$status" == "Full" ]]; then
    icon="󱊣"
    class="full"
elif (( capacity <= 15 )); then
    icon="󱊡"
    class="critical"
elif (( capacity <= 30 )); then
    icon="󱊡"
    class="warning"
else
    icon="󱊡"
    class="normal"
fi

tooltip="$status: ${capacity}%"

echo "{\"text\": \"$icon ${capacity}%\", \"tooltip\": \"$tooltip\", \"class\": \"$class\"}"
