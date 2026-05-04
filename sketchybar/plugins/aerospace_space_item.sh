#!/bin/sh
# Per-workspace item: instant highlight on workspace change (Josean / native space pattern:
# each item updates only itself on the event, so SketchyBar can run scripts in parallel).
# Space colors inlined to avoid sourcing full colors.sh on every item × every switch (keep in sync with colors.sh).

[ "$SENDER" = "aerospace_workspace_change" ] || exit 0

if [ -z "$CONFIG_DIR" ]; then
  CONFIG_DIR="$HOME/.config/sketchybar"
fi
SPACE_BG_COLOR=0xffffffff CURRENT_SPACE_BG=0xff8b0000 CURRENT_SPACE_TEXT=0xffffffff SPACE_TEXT_COLOR=0xff000000
# shellcheck source=/dev/null
. "$CONFIG_DIR/plugins/aerospace_focus_from_event.sh"

sid="${NAME#space.}"
[ -n "$sid" ] || exit 0

if [ "$current_workspace" = "$sid" ]; then
  sketchybar --set "$NAME" \
             background.color="$CURRENT_SPACE_BG" \
             label.color="$CURRENT_SPACE_TEXT" \
             icon.color="$CURRENT_SPACE_TEXT" 2>/dev/null
else
  sketchybar --set "$NAME" \
             background.color="$SPACE_BG_COLOR" \
             label.color="$SPACE_TEXT_COLOR" \
             icon.color="$SPACE_TEXT_COLOR" 2>/dev/null
fi
