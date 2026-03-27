#!/bin/bash
# memory-info.sh — Memory info popup for waybar

source "$(dirname "$0")/lib.sh"
ID=91004

msg=""

# ── RAM ──
read -r _ total used free shared bufcache avail < <(free -h | grep '^Mem:')
msg+="$(section "$GREEN" '  RAM')  $used / $total  <span color='${DIM}'>(avail: $avail)</span>\n"

# ── Swap ──
read -r _ stotal sused sfree < <(free -h | grep '^Swap:')
if [ "$sused" = "0B" ] || [ "$sused" = "0Bi" ] || [ "$sused" = "0" ]; then
    msg+="$(section "$BLUE" '  Swap')  <span color='${DIM}'>not in use</span>  ($stotal total)\n"
else
    msg+="$(section "$BLUE" '  Swap')  $sused / $stotal\n"
fi

# ── Top 5 by memory ──
msg+="$(section "$YELLOW" '  Top Processes')\n"
top_procs=$(ps aux --sort=-%mem --no-headers | head -5 | awk '{
    cmd = $11;
    for(i=12;i<=NF;i++) cmd = cmd " " $i;
    printf "  %-8s %5.1f%%  %s\n", $1, $4, substr(cmd,1,35)
}' | sanitize)
msg+="$top_procs\n"

echo -e "$msg" > "$HOME/.config/ags/info-content"
ags request info Memory 2>/dev/null || notify-send -t 10000 "Memory" "$msg"
