#!/usr/bin/env python3
"""tmux-resurrect post-save hook: make Claude Code panes restore their conversation.

Resurrect saves each pane's command line and types it back on restore. For a
Claude pane that command ("claude -r", "claude attach 3c7c0c80", or nothing when
claude is the pane's own process) does not say which conversation was open, and
after a reboot "claude attach" has nothing to attach to. This rewrites each Claude
pane's saved command to "claude --resume <session id>", looked up in Claude Code's
per-process records (~/.claude/sessions/<pid>.json). "claude agents" is kept.

Usage (resurrect passes the save file): resurrect-claude.py <state file>
"""
import glob, json, os, subprocess, sys

SESSIONS = os.path.expanduser("~/.claude/sessions")


def records():
    out = {}
    for f in glob.glob(os.path.join(SESSIONS, "*.json")):
        try:
            with open(f) as fh:
                out[os.path.basename(f)[:-5]] = json.load(fh)
        except (OSError, ValueError):
            pass
    return out


def children():
    kids = {}
    for stat in glob.glob("/proc/[0-9]*/stat"):
        try:
            with open(stat) as fh:
                fields = fh.read().rsplit(")", 1)[1].split()
            kids.setdefault(fields[1], []).append(stat.split("/")[2])
        except (OSError, IndexError):
            pass
    return kids


def argv(pid):
    try:
        with open(f"/proc/{pid}/cmdline", "rb") as fh:
            return [a.decode(errors="replace") for a in fh.read().split(b"\0") if a]
    except OSError:
        return []


def claude_pid(pane_pid, kids):
    """The claude process in a pane: the pane process itself or one of its children."""
    for pid in [pane_pid] + kids.get(pane_pid, []):
        args = argv(pid)
        if args and os.path.basename(args[0]) == "claude":
            return pid, args
    return None, []


def resume_command(pid, args, recs):
    if len(args) > 1 and args[1] == "agents":
        return "claude agents"
    if len(args) > 2 and args[1] == "attach":
        job = args[2]
        for r in recs.values():
            if r.get("jobId") == job or str(r.get("sessionId", "")).startswith(job):
                return f"claude --resume {r['sessionId']}"
        hits = glob.glob(os.path.expanduser(f"~/.claude/projects/*/{job}*.jsonl"))
        if len(hits) == 1:
            return f"claude --resume {os.path.basename(hits[0])[:-6]}"
        return None
    sid = recs.get(pid, {}).get("sessionId")
    return f"claude --resume {sid}" if sid else None


def main(path):
    panes = subprocess.run(
        ["tmux", "list-panes", "-a", "-F", "#{session_name}\t#{window_index}\t#{pane_index}\t#{pane_pid}"],
        capture_output=True, text=True).stdout.splitlines()
    pane_pid = {tuple(p.split("\t")[:3]): p.split("\t")[3] for p in panes if p.count("\t") == 3}
    recs, kids = records(), children()

    with open(path) as fh:
        lines = fh.read().split("\n")
    for i, line in enumerate(lines):
        f = line.split("\t")
        # pane, session, window, window_active, flags, pane_index, title, dir, pane_active, command, :full_command
        if len(f) < 11 or f[0] != "pane":
            continue
        pid, args = claude_pid(pane_pid.get((f[1], f[2], f[5]), ""), kids)
        cmd = resume_command(pid, args, recs) if pid else None
        if cmd:
            f[9], f[10] = "claude", ":" + cmd
            lines[i] = "\t".join(f)
    with open(path, "w") as fh:
        fh.write("\n".join(lines))


if __name__ == "__main__":
    main(sys.argv[1])
