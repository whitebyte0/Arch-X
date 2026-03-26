#!/bin/bash
# network-info.sh — curated network info popup for waybar

source "$(dirname "$0")/lib.sh"
ID=91001

msg=""

# ── Interfaces ──
msg+="$(section "$GREEN" '  Interfaces')\n"
while IFS= read -r line; do
    iface=$(echo "$line" | awk '{print $1}')
    addr=$(echo "$line" | awk '{for(i=3;i<=NF;i++) printf "%s ", $i; print ""}' | xargs)
    [ -z "$addr" ] && addr="<span color='${DIM}'>no address</span>"
    msg+="  $iface  $addr\n"
done < <(ip -br addr | grep UP)
msg+="\n"

# ── Gateway ──
gw=$(ip route | awk '/default/{print $3; exit}')
msg+="$(section "$BLUE" '  Gateway')  ${gw:-none}\n"

# ── DNS servers ──
dns=$(resolvectl status 2>/dev/null | awk '/Current DNS/{print $NF}' | head -3 | tr '\n' '  ')
[ -z "$dns" ] && dns=$(awk '/^nameserver/{print $2}' /etc/resolv.conf 2>/dev/null | head -3 | tr '\n' '  ')
msg+="$(section "$BLUE" '  DNS')  ${dns:-unknown}\n"

# ── DNS resolution check ──
dig_result=$(dig +short +timeout=2 +tries=1 archlinux.org 2>/dev/null | head -1)
if [ -n "$dig_result" ]; then
    msg+="$(section "$GREEN" '  Resolve')  <span color='${GREEN}'>OK</span>  <span color='${DIM}'>($dig_result)</span>\n"
else
    msg+="$(section "$PINK" '  Resolve')  <span color='${PINK}'>FAIL</span>\n"
fi
msg+="\n"

# ── VPN status ──
vpn_status=""
wg_ifaces=$(ip link show type wireguard 2>/dev/null | awk -F': ' '/^[0-9]/{print $2}')
[ -n "$wg_ifaces" ] && vpn_status+="WG: $wg_ifaces  "
pgrep -x openvpn >/dev/null 2>&1 && vpn_status+="OpenVPN: active  "
nmcli_vpn=$(nmcli -t -f NAME,TYPE con show --active 2>/dev/null | grep -i vpn | cut -d: -f1)
[ -n "$nmcli_vpn" ] && vpn_status+="VPN: $nmcli_vpn  "
if [ -n "$vpn_status" ]; then
    msg+="$(section "$GREEN" '󰖂  VPN')  <span color='${GREEN}'>$vpn_status</span>\n"
else
    msg+="$(section "$DIM" '󰖂  VPN')  <span color='${DIM}'>inactive</span>\n"
fi
msg+="\n"

# ── TCP connections ──
tcp_est=$(ss -t state established 2>/dev/null | tail -n +2 | wc -l)
msg+="$(section "$YELLOW" '  TCP')  $tcp_est established\n\n"

# ── Listening ports ──
msg+="$(section "$YELLOW" '  Listening')\n"
ports=$(ss -tlnp --no-header 2>/dev/null | awk '{
    split($4, a, ":");
    port = a[length(a)];
    proc = $6;
    gsub(/.*users:\(\("/, "", proc);
    gsub(/".*/, "", proc);
    printf "  :%s  %s\n", port, proc
}' | sort -t: -k2 -n -u | head -10 | sanitize)
if [ -n "$ports" ]; then
    msg+="$ports\n"
else
    msg+="  <span color='${DIM}'>none</span>\n"
fi

notify-send -t 12000 -h "string:x-canonical-private-synchronous:$ID" "Network" "$msg"
