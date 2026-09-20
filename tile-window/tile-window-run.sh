#!/bin/bash
scripts="$HOME/.config/karabiner/scripts"
FIFO="$scripts/tile-window.fifo"
rm -f "$FIFO"
mkfifo "$FIFO"
exec /usr/bin/osascript -l JavaScript "$scripts/tile-window.js"
