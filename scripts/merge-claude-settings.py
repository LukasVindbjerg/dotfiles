#!/usr/bin/env python3
"""Set the Claude Code theme and status line in ~/.claude/settings.json.

Only these two keys are touched; permissions, MCP servers and everything else
stay as they are. The file is backed up first and created if missing.
"""
import json, os, shutil, time

path = os.path.expanduser("~/.claude/settings.json")
wanted = {
    "theme": "custom:claude-orange",
    "statusLine": {"type": "command", "command": "~/dotfiles/bin/claude-statusline"},
}

settings = {}
if os.path.exists(path):
    try:
        with open(path) as f:
            settings = json.load(f)
    except ValueError:
        print(f"  skip  {path} is not valid JSON; add these keys by hand: {json.dumps(wanted)}")
        raise SystemExit(0)

if all(settings.get(k) == v for k, v in wanted.items()):
    print("  ok    Claude theme and status line already set")
    raise SystemExit(0)

os.makedirs(os.path.dirname(path), exist_ok=True)
if os.path.exists(path):
    shutil.copy2(path, f"{path}.bak-{time.strftime('%Y%m%d-%H%M%S')}")
settings.update(wanted)
with open(path, "w") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")
print("  done  Claude theme (Claude Orange) and status line set")
