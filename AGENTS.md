# macOS-setup

After changing any of these live files or this repo, sync, commit, and push to `origin/main`. Do not wait to be asked.

Live sources:

- `~/.config/karabiner/karabiner.json`
- `~/.config/linearmouse/linearmouse.json`
- `~/Library/Application Support/Cursor/User/keybindings.json`
- `~/.config/karabiner/scripts/tile.sh`
- `~/.config/karabiner/scripts/tile-send.c`
- `~/.config/karabiner/scripts/tile-window.js`
- `~/.config/karabiner/scripts/tile-window-daemon.swift`
- `~/.config/karabiner/scripts/tile-window-run.sh`
- `~/Library/LaunchAgents/` tile-window LaunchAgent

`./sync.sh` strips the home directory and local bundle id before writing. Do not commit unsanitized copies.
