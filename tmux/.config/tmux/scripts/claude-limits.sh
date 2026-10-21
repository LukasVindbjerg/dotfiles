#!/bin/sh
# Claude's 5-hour and 7-day usage limits, for the Claude bubble in the tmux status bar.
# Saved by ~/dotfiles/bin/claude-statusline whenever a Claude session updates; a window whose reset time has passed is dropped.
limits=$(python3 -c '
import json, os, time
try: d = json.load(open(os.path.expanduser("~/.cache/claude-limits.json")))
except Exception: raise SystemExit
now = time.time()
out = [f"{label} {w.get("used_percentage", 0):.0f}%" for key, label in (("five_hour", "5h"), ("seven_day", "7d"))
       if (w := d.get(key)) and w.get("resets_at", 0) > now]
print("  ".join(out))' 2>/dev/null)

printf '%s' "${limits:-–}"
