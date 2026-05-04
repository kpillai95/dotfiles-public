#!/bin/sh
# AeroSpace → SketchyBar (no bash -lc). Optional $1 = focused workspace for optimistic updates from keybindings
# (runs before workspace switch finishes); callback uses AEROSPACE_FOCUSED_WORKSPACE when $1 is empty.
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
ws="${1:-$AEROSPACE_FOCUSED_WORKSPACE}"
[ -n "$ws" ] || exit 0
for sb in /opt/homebrew/bin/sketchybar /usr/local/bin/sketchybar; do
  if [ -x "$sb" ]; then
    exec "$sb" --trigger aerospace_workspace_change "FOCUSED_WORKSPACE=$ws"
  fi
done
exit 1
