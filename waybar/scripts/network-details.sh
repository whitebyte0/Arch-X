#!/bin/bash
# network-details.sh — detailed network info popup (right-click)

source "$(dirname "$0")/lib.sh"
ID=91002

msg=""

# ── Active connections ──
msg+="$(section "$GREEN" '  Active Connections')\n"
while IFS=: read -r name type device _; do
    [ -z "$name" ] && continue
    msg+="  $(echo "$name" | sanitize) <span color='${DIM}'>($type on $device)</span>\n"
done < <(nmcli -t -f NAME,TYPE,DEVICE con show --active 2>/dev/null)

# ── WiFi details if applicable ──
wifi_dev=$(nmcli -t -f DEVICE,TYPE dev status 2>/dev/null | awk -F: '/wifi$/{print $1; exit}')
if [ -n "$wifi_dev" ]; then
    msg+="$(section "$BLUE" '󰤨  WiFi Details')\n"
    wifi_info=$(nmcli -t -f SSID,SIGNAL,FREQ,SECURITY dev wifi list ifname "$wifi_dev" --rescan no 2>/dev/null | head -5)
    while IFS=: read -r ssid signal freq security; do
        [ -z "$ssid" ] && continue
        msg+="  $(echo "$ssid" | sanitize)  ${signal}%  ${freq}  $security\n"
    done <<< "$wifi_info"
fi

# ── Full address info ──
msg+="$(section "$BLUE" '  Addresses')\n"
while IFS= read -r line; do
    iface=$(echo "$line" | awk '{print $1}')
    state=$(echo "$line" | awk '{print $2}')
    addrs=$(echo "$line" | awk '{for(i=3;i<=NF;i++) printf "%s ", $i}' | xargs)
    msg+="  $iface <span color='${DIM}'>[$state]</span>  $addrs\n"
done < <(ip -br addr 2>/dev/null)

# ── Routes ──
msg+="$(section "$BLUE" '  Routes')\n"
routes=$(ip route 2>/dev/null | head -8 | sanitize)
msg+="$routes\n"

rendered=$(echo -e "$msg")
ags request info "Network Details" "$rendered" 2>/dev/null || notify-send -t 15000 "Network Details" "$msg"
