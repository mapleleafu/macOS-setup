#!/bin/bash
mode="$1"
scripts="$HOME/.config/karabiner/scripts"
rm -f /tmp/tile-window.untrusted
"$scripts/tile-send" "$mode" || true
sleep 0.03
if [ -f /tmp/tile-window.untrusted ]; then
  exec /usr/bin/osascript -l JavaScript "$scripts/tile-window.js" "$mode"
fi
