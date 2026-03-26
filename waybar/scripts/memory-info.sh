#!/bin/bash
# memory-info.sh — Memory info popup for waybar

GREEN='#ffffff'
YELLOW='#f9e2af'
BLUE='#89b4fa'
DIM='#6c7086'
ID=91004

sanitize() { sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'; }
section() { echo "<span color='${1}'><b>$2</b></span>"; }

msg=""

# ── RAM ──
read -r _ total used free shared bufcache avail < <(free -h | grep '^Mem:')
msg+="$(section "$GREEN" '  RAM')  $used / $total  <span color='${DIM}'>(avail: $avail)</span>\n\n"

# ── Swap ──
read -r _ stotal sused sfree < <(free -h | grep '^Swap:')
if [ "$sused" = "0B" ] || [ "$sused" = "0Bi" ] || [ "$sused" = "0" ]; then
    msg+="$(section "$BLUE" '  Swap')  <span color='${DIM}'>not in use</span>  ($stotal total)\n\n"
else
    msg+="$(section "$BLUE" '  Swap')  $sused / $stotal\n\n"
fi

# ── Top 5 by memory ──
msg+="$(section "$YELLOW" '  Top Processes')\n"
top_procs=$(ps aux --sort=-%mem --no-headers | head -5 | awk '{
    cmd = $11;
    for(i=12;i<=NF;i++) cmd = cmd " " $i;
    printf "  %-8s %5.1f%%  %s\n", $1, $4, substr(cmd,1,35)
}' | sanitize)
msg+="$top_procs\n"

dunstify -r "$ID" -t 10000 "Memory" "$msg"
