#!/usr/bin/env python3
"""Apply the terminal look to the Windows side, from inside WSL.

Windows Terminal: add the Catppuccin Mocha scheme; on this distro's profile set
the Nerd Font, the scheme and the Linux home as start folder; make it the default
profile.
VS Code: use the Nerd Font in the integrated terminal.

Usage: merge-windows-settings.py <scheme.json> <localappdata> <appdata>
Each file is backed up first. A file with comments (not strict JSON) is skipped
with a message rather than rewritten.
"""
import getpass, glob, json, os, shutil, sys, time

FONT = "JetBrainsMono Nerd Font"
scheme_file, localappdata, appdata = sys.argv[1:4]
distro = os.environ.get("WSL_DISTRO_NAME", "")
stamp = time.strftime("%Y%m%d-%H%M%S")


def load(path):
    try:
        with open(path, encoding="utf-8-sig") as f:
            return json.load(f)
    except ValueError:
        print(f"  skip  {path} has comments or is not plain JSON; apply its settings by hand (see README)")
        return None


def save(path, data, before):
    if data == before:
        print(f"  ok    {path} already set")
        return
    shutil.copy2(path, f"{path}.bak-{stamp}")
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=4, ensure_ascii=False)
    print(f"  done  {path} updated")


# --- Windows Terminal (Store, Preview or unpackaged install) ---
wt_paths = glob.glob(os.path.join(localappdata, "Packages", "Microsoft.WindowsTerminal*", "LocalState", "settings.json"))
wt_paths += glob.glob(os.path.join(localappdata, "Microsoft", "Windows Terminal", "settings.json"))
if not wt_paths:
    print("  skip  Windows Terminal settings not found (open Windows Terminal once, then rerun)")
for path in wt_paths:
    data = load(path)
    if data is None:
        continue
    before = json.loads(json.dumps(data))
    with open(scheme_file) as f:
        scheme = json.load(f)
    data["schemes"] = [s for s in data.get("schemes", []) if s.get("name") != scheme["name"]] + [scheme]

    profiles = data.get("profiles", {})
    plist = profiles.get("list", []) if isinstance(profiles, dict) else profiles
    mine = [p for p in plist if p.get("source") == "Microsoft.WSL" and p.get("name") == distro]
    if not mine:
        print(f"  skip  no Windows Terminal profile named {distro!r}; only the colour scheme was added")
    for p in mine:
        p.setdefault("font", {})["face"] = FONT
        p["colorScheme"] = scheme["name"]
        p["startingDirectory"] = f"\\\\wsl.localhost\\{distro}\\home\\{getpass.getuser()}"
        data["defaultProfile"] = p["guid"]
    save(path, data, before)

# --- VS Code user settings ---
vs = os.path.join(appdata, "Code", "User", "settings.json")
if os.path.exists(vs):
    data = load(vs)
    if data is not None:
        before = dict(data)
        data["terminal.integrated.fontFamily"] = f"'{FONT}', monospace"
        save(vs, data, before)
else:
    print("  skip  VS Code user settings not found")
