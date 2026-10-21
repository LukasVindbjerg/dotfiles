#!/bin/sh
# CPU and memory in use for the tmux status bar.
# CPU is measured since the previous call (tmux calls this every status-interval).
state="${TMPDIR:-/tmp}/tmux-sysinfo-$(id -u)"

read -r _ u n s i w x y z _ < /proc/stat
total=$((u + n + s + i + w + x + y + z))
idle=$((i + w))
cpu=0
if read -r prev_total prev_idle 2>/dev/null < "$state" && [ "$total" -gt "$prev_total" ]; then
  cpu=$(( 100 * ((total - prev_total) - (idle - prev_idle)) / (total - prev_total) ))
fi
echo "$total $idle" > "$state"

mem=$(awk '/^MemTotal/ {t = $2} /^MemAvailable/ {a = $2} END {printf "%.1f/%.0f GiB", (t - a) / 1048576, t / 1048576}' /proc/meminfo)
printf 'CPU %d%%  RAM %s' "$cpu" "$mem"
