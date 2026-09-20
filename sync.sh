#!/usr/bin/env bash
# Copy live machine configs into this repo, with home paths stripped.
set -euo pipefail
root="$(cd "$(dirname "$0")" && pwd)"

python3 - "$root" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
home = Path.home()
home_s = str(home)
user = home.name
local_bundle = f"com.{user}"

def sanitize(text: str) -> str:
    text = text.replace(home_s, "$HOME")
    text = text.replace(local_bundle, "com.macos-setup")
    return text

def copy_sanitized(src: Path, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(sanitize(src.read_text()))

copy_sanitized(home / ".config/karabiner/karabiner.json", root / "karabiner.json")
k = json.loads((root / "karabiner.json").read_text())
rules = k["profiles"][0]["complex_modifications"]["rules"]
(root / "karabiner-elements.json").write_text(json.dumps(rules, indent=4) + "\n")

copy_sanitized(home / ".config/linearmouse/linearmouse.json", root / "linearmouse.json")
copy_sanitized(
    home / "Library/Application Support/Cursor/User/keybindings.json",
    root / "keybindings.json",
)

scripts = home / ".config/karabiner/scripts"
for name in (
    "tile.sh",
    "tile-send.c",
    "tile-window.js",
    "tile-window-run.sh",
    "tile-window-daemon.swift",
):
    src = scripts / name
    if src.exists():
        copy_sanitized(src, root / "tile-window" / name)

plist = home / "Library/LaunchAgents" / f"{local_bundle}.tile-window.plist"
if plist.exists():
    copy_sanitized(plist, root / "tile-window" / "tile-window.plist")
    old = root / "tile-window" / f"{local_bundle}.tile-window.plist"
    if old.exists():
        old.unlink()

skip = {root / "sync.sh"}
leaks = []
for path in root.rglob("*"):
    if not path.is_file() or ".git" in path.parts or path in skip:
        continue
    try:
        text = path.read_text()
    except UnicodeDecodeError:
        continue
    if user in text or home_s in text:
        leaks.append(str(path))
if leaks:
    raise SystemExit("personal path leaked:\n" + "\n".join(leaks))
PY
