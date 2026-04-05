#!/bin/bash
# cpu-info.sh — CPU info popup (data gathering based on github.com/Szerwigi1410/cpuinfo)

source "$(dirname "$0")/lib.sh"

msg=""

# ── Model ──
cpu_name=$(grep -m 1 'model name' /proc/cpuinfo | awk -F: '{print $2}' | xargs)
brand=$(lscpu | grep -Eio 'intel|amd' | head -1)
msg+="$(section "$GREEN" '  CPU')  ${cpu_name:-Unknown}\n"

# ── Cores + Threads ──
cores=$(lscpu | grep 'Core(s) per socket' | awk -F: '{print $2}' | xargs)
threads=$(nproc)
tpc=$(lscpu | grep 'Thread(s) per core' | awk -F: '{print $2}' | xargs)
msg+="$(section "$BLUE" '  Cores')  $cores cores, $threads threads ($tpc per core)\n"

# ── Frequency ──
cur_mhz=$(lscpu | grep 'CPU MHz' | awk -F: '{print $2}' | xargs | sed 's/\.[0]*$//')
min_mhz=$(lscpu | grep 'CPU min MHz' | awk -F: '{print $2}' | xargs | sed 's/\.[0]*$//')
max_mhz=$(lscpu | grep 'CPU max MHz' | awk -F: '{print $2}' | xargs | sed 's/\.[0]*$//')
[ -z "$cur_mhz" ] && cur_mhz=$(awk '{print int($1/1000)}' /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null)
msg+="$(section "$BLUE" '  Freq')  ${cur_mhz:-?} MHz  (${min_mhz:-?} - ${max_mhz:-?})\n"

# ── Cache ──
l1d=$(lscpu | grep 'L1d' | awk -F: '{print $2}' | xargs | head -1)
l2=$(lscpu | grep 'L2' | awk -F: '{print $2}' | xargs)
l3=$(lscpu | grep 'L3' | awk -F: '{print $2}' | xargs)
msg+="$(section "$BLUE" '  Cache')  L1d: $l1d  L2: $l2  L3: $l3\n"

# ── Load average ──
read -r one five fifteen _ < /proc/loadavg
msg+="$(section "$YELLOW" '  Load')  $one  $five  $fifteen\n"

# ── Top 5 by CPU ──
msg+="$(section "$YELLOW" '  Top Processes')\n"
top_procs=$(ps aux --sort=-%cpu --no-headers | head -5 | awk '{
    cmd = $11;
    for(i=12;i<=NF;i++) cmd = cmd " " $i;
    printf "  %-8s %5.1f%%  %s\n", $1, $3, substr(cmd,1,35)
}' | sanitize)
msg+="$top_procs\n"

notify-send -a system -t 15000 "CPU" "$(echo -e "$msg")"
