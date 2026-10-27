#!/usr/bin/env python3
"""tmux prefix + i: copy the session ID of the Claude Code session shown in a pane.

Sources, most reliable first:
  1. ~/.cache/claude-panes/<pane>.json, written by the Claude status line
     (~/dotfiles/bin/claude-statusline) for what the pane shows, if newer than the
     claude process now running there (so it also follows a /resume switch);
  2. a viewer pane, "claude attach <short id>": the full ID from the saved transcript;
  3. Claude Code's record for the pane's claude process (~/.claude/sessions/<pid>.json).
Copies the full ID to the Windows clipboard and reports in the tmux status line.

Usage: copy-claude-session.py <pane id, e.g. %12>
"""
import glob, json, os, subprocess, sys

H = os.path.expanduser("~")


def tmux_msg(text):
    subprocess.run(["tmux", "display-message", text])


def argv(pid):
    try:
        with open(f"/proc/{pid}/cmdline", "rb") as f:
            return [a.decode(errors="replace") for a in f.read().split(b"\0") if a]
    except OSError:
        return []


def claude_in_pane(pane_pid):
    """The claude process in a pane: the pane process itself or one of its children."""
    kids = subprocess.run(["pgrep", "-P", pane_pid], capture_output=True, text=True).stdout.split()
    for pid in [pane_pid] + kids:
        a = argv(pid)
        if a and os.path.basename(a[0]) == "claude":
            return pid, a
    return None, []


def started(pid):
    """When a process started, in seconds since the epoch."""
    with open(f"/proc/{pid}/stat") as f:
        ticks = int(f.read().rsplit(")", 1)[1].split()[19])
    with open("/proc/stat") as f:
        boot = next(int(l.split()[1]) for l in f if l.startswith("btime"))
    return boot + ticks / os.sysconf("SC_CLK_TCK")


def name_of(sid):
    for f in glob.glob(f"{H}/.claude/sessions/*.json"):
        try:
            with open(f) as fh:
                r = json.load(fh)
        except (OSError, ValueError):
            continue
        if r.get("sessionId") == sid and r.get("name"):
            return r["name"]
    return ""


def find(pane):
    pane_pid = subprocess.run(["tmux", "display", "-p", "-t", pane, "#{pane_pid}"],
                              capture_output=True, text=True).stdout.strip()
    pid, args = claude_in_pane(pane_pid)
    if not pid:
        return None, None

    note = f"{H}/.cache/claude-panes/{pane.lstrip('%')}.json"
    try:
        if os.path.getmtime(note) >= started(pid):
            with open(note) as f:
                d = json.load(f)
            return d["session_id"], d.get("name") or name_of(d["session_id"])
    except (OSError, ValueError, KeyError):
        pass

    if len(args) > 2 and args[1] == "attach":
        hits = glob.glob(f"{H}/.claude/projects/*/{args[2]}*.jsonl")
        if len(hits) == 1:
            sid = os.path.basename(hits[0])[:-len(".jsonl")]
            return sid, name_of(sid)
        return None, None

    try:
        with open(f"{H}/.claude/sessions/{pid}.json") as f:
            r = json.load(f)
        return r.get("sessionId"), r.get("name") or ""
    except (OSError, ValueError):
        return None, None


def main(pane):
    sid, name = find(pane)
    if not sid:
        tmux_msg("No Claude session found in this pane")
        return
    subprocess.run(["clip.exe"], input=sid.encode())
    tmux_msg(f"Copied session ID {sid}" + (f"  ({name})" if name else ""))


if __name__ == "__main__":
    main(sys.argv[1])
