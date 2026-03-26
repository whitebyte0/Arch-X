#!/bin/bash
# cpu-info.sh — CPU info popup for waybar

source "$(dirname "$0")/lib.sh"
ID=91003

msg=""

# ── Load average ──
read -r one five fifteen _ < /proc/loadavg
msg+="$(section "$GREEN" '  Load')  $one  $five  $fifteen\n\n"

# ── Cores + frequency ──
cores=$(nproc)
freq=$(awk '/cpu MHz/{sum+=$4; n++} END{if(n>0) printf "%.0f", sum/n}' /proc/cpuinfo)
msg+="$(section "$BLUE" '  Cores')  $cores @ ${freq} MHz\n\n"

# ── Top 5 by CPU ──
msg+="$(section "$YELLOW" '  Top Processes')\n"
top_procs=$(ps aux --sort=-%cpu --no-headers | head -5 | awk '{
    cmd = $11;
    for(i=12;i<=NF;i++) cmd = cmd " " $i;
    printf "  %-8s %5.1f%%  %s\n", $1, $3, substr(cmd,1,35)
}' | sanitize)
msg+="$top_procs\n"

echo -e "$msg" > "$HOME/.config/ags/info-content"
ags request info CPU 2>/dev/null || notify-send -t 10000 "CPU" "$msg"
