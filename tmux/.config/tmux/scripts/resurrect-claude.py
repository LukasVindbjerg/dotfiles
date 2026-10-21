#!/usr/bin/env python3
"""tmux-resurrect post-save hook: make Claude Code panes restore their conversation.

Resurrect saves each pane's command line and types it back on restore. For a
Claude pane that command ("claude -r", "claude -c", or nothing when claude is the
pane's own process) does not say which conversation was open. This rewrites every
Claude pane's saved command, using Claude Code's per-process records
(~/.claude/sessions/<pid>.json), so that a restore can never copy a conversation:
  claude attach <id>   -> claude attach <id>   (background session; restarts it under its own ID)
  claude agents        -> claude agents
  a normal session     -> cd <its folder> && claude --resume <id>, if only one pane had it
  anything unclear     -> a one-line note in the pane, Claude is not started
Restoring a viewer as "claude --resume" once turned a background session into a
second, separate copy of the same conversation; hence the cautious rules.

Usage (resurrect passes the save file): resurrect-claude.py <state file>
            Dry run, writes nothing:   resurrect-claude.py --dry-run
"""
import glob, json, os, re, shlex, subprocess, sys

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


def note(text):
    """Restore nothing; leave a one-line note in the pane instead."""
    return "echo " + shlex.quote(f"[restore] {text}; reopen it with: claude agents (or claude -r)")


def restore_command(pid, args, recs, claimed):
    """What to type into the pane on restore. Never a command that could copy a conversation:
    a background session is reopened with 'claude attach' (same ID, refuses if open elsewhere),
    a normal session is resumed only if exactly one pane had it, anything unclear gets a note."""
    if len(args) > 1 and args[1] == "agents":
        return "claude agents"

    if len(args) > 2 and args[1] == "attach":
        target = args[2]
        if not re.fullmatch(r"[0-9a-f]{8}", target):  # attached by name: find its short ID
            target = next((r.get("jobId") for r in recs.values()
                           if r.get("name") == target and r.get("jobId")), None)
        if not target:
            return note(f"a background session ({args[2]}) was open here")
        return f"claude attach {target}"

    rec = recs.get(pid, {})
    sid = rec.get("sessionId")
    if not sid or rec.get("kind") != "interactive":
        return note("a Claude session was open here")
    # Also running in the background (e.g. moved there by /resume): this pane may show something else.
    if any(r.get("sessionId") == sid and r.get("kind") == "bg" for r in recs.values()):
        return note(f"session {sid[:8]} also runs in the background")
    if sid in claimed:  # the same conversation in two panes: only the first one resumes it
        return note(f"session {sid[:8]} was also open in another pane")
    claimed.add(sid)
    cwd = rec.get("cwd")
    return (f"cd {shlex.quote(cwd)} && " if cwd else "") + f"claude --resume {sid}"


def plan(lines):
    """Map each saved pane line to its restore command (only panes running claude)."""
    panes = subprocess.run(
        ["tmux", "list-panes", "-a", "-F", "#{session_name}\t#{window_index}\t#{pane_index}\t#{pane_pid}"],
        capture_output=True, text=True).stdout.splitlines()
    pane_pid = {tuple(p.split("\t")[:3]): p.split("\t")[3] for p in panes if p.count("\t") == 3}
    recs, kids, claimed = records(), children(), set()
    out = {}
    for i, line in enumerate(lines):
        f = line.split("\t")
        # pane, session, window, window_active, flags, pane_index, title, dir, pane_active, command, :full_command
        if len(f) < 11 or f[0] != "pane":
            continue
        pid, args = claude_pid(pane_pid.get((f[1], f[2], f[5]), ""), kids)
        if pid:
            out[i] = (f"{f[1]}:{f[2]}.{f[5]}", " ".join(args), restore_command(pid, args, recs, claimed))
    return out


def main(path):
    with open(path) as fh:
        lines = fh.read().split("\n")
    for i, (_, _, cmd) in plan(lines).items():
        f = lines[i].split("\t")
        f[9], f[10] = "claude", ":" + cmd
        lines[i] = "\t".join(f)
    with open(path, "w") as fh:
        fh.write("\n".join(lines))


def dry_run():
    """Show what a save would record for the panes open right now. Writes nothing."""
    live = subprocess.run(
        ["tmux", "list-panes", "-a", "-F", "pane\t#{session_name}\t#{window_index}\t\t\t#{pane_index}\t\t\t\t\t:"],
        capture_output=True, text=True).stdout.splitlines()
    for pane, was, cmd in plan(live).values():
        print(f"{pane:12} {was[:40]:40} -> {cmd}")


if __name__ == "__main__":
    # resurrect-claude.py <state file>   rewrite the Claude panes in a resurrect save
    # resurrect-claude.py --dry-run      only show what it would restore for the panes open now
    dry_run() if sys.argv[1:] == ["--dry-run"] else main(sys.argv[1])
