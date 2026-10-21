#!/bin/sh
# CPU and memory in use, plus Claude's 5-hour and 7-day usage limits, for the tmux status bar.
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
# Saved by ~/dotfiles/bin/claude-statusline whenever a Claude session updates; a window whose reset time has passed is dropped.
limits=$(python3 -c '
import json, os, time
try: d = json.load(open(os.path.expanduser("~/.cache/claude-limits.json")))
except Exception: raise SystemExit
now = time.time()
out = [f"{label} {w.get("used_percentage", 0):.0f}%" for key, label in (("five_hour", "5h"), ("seven_day", "7d"))
       if (w := d.get(key)) and w.get("resets_at", 0) > now]
print("  ".join(out))' 2>/dev/null)

printf 'CPU %d%%  RAM %s' "$cpu" "$mem"
[ -n "$limits" ] && printf '  Claude %s' "$limits"
