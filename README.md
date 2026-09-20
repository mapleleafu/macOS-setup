# macOS-setup

Live snapshots of the machine setup that makes this Mac feel like the Windows/WSL layout.

## Files

| Path | Source |
|---|---|
| `karabiner.json` | Full Karabiner-Elements profile |
| `karabiner-elements.json` | Complex modification rules only |
| `linearmouse.json` | Linear Mouse (Lightspeed receiver) |
| `keybindings.json` | Cursor / VS Code |
| `tile-window/` | Option+arrow window tiling helper |

## Tiling

Option+Up fills the window. Option+Left / Option+Right snap to a half.

Karabiner calls `tile.sh`. That talks to `Tile Window.app` when Accessibility actually attaches, and falls back to `tile-window.js` via osascript.

Keyboard Control+Up / Control+Down scroll the editor. Control+Option+Up is Mission Control. G HUB G4 sends Control+Option+Up.

## Sync

```bash
~/dev/personal/macOS-setup/sync.sh
```

Copies the live files above into this repo. A Cursor hook commits and pushes after those files change, same as [gtools](https://github.com/mapleleafu/gtools).
