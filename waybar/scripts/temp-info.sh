#!/bin/bash
# temp-info.sh — Temperature info popup

source "$(dirname "$0")/lib.sh"

msg=""

msg+="$(section "$GREEN" '  Thermal Zones')\n"
for zone in /sys/class/thermal/thermal_zone*/; do
    [ -d "$zone" ] || continue
    name=$(cat "$zone/type" 2>/dev/null || echo "unknown")
    temp=$(cat "$zone/temp" 2>/dev/null || echo "0")
    temp_c=$((temp / 1000))
    color="$GREEN"
    [ "$temp_c" -ge 70 ] && color="$YELLOW"
    [ "$temp_c" -ge 85 ] && color="$PINK"
    msg+="  $name  <span color='${color}'>${temp_c}°C</span>\n"
done

# hwmon sensors if available
if [ -d /sys/class/hwmon ]; then
    msg+="$(section "$BLUE" '  Hardware Sensors')\n"
    for hw in /sys/class/hwmon/hwmon*/; do
        [ -d "$hw" ] || continue
        hwname=$(cat "$hw/name" 2>/dev/null || echo "unknown")
        for inp in "$hw"/temp*_input; do
            [ -f "$inp" ] || continue
            label_file="${inp/_input/_label}"
            label=$(cat "$label_file" 2>/dev/null || basename "$inp" | sed 's/_input//')
            val=$(($(cat "$inp") / 1000))
            color="$GREEN"
            [ "$val" -ge 70 ] && color="$YELLOW"
            [ "$val" -ge 85 ] && color="$PINK"
            msg+="  $hwname/$label  <span color='${color}'>${val}°C</span>\n"
        done
    done
fi

notify-send -a system -t 15000 "Temperature" "$(echo -e "$msg")"
