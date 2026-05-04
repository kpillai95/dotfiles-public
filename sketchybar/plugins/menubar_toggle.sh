#!/bin/sh

# Keep sketchybar behind windows by default.
# Only step aside (topmost=off already) when native menu bar slides in — the
# system panel naturally renders on top, so no extra logic is needed here.
sketchybar --bar topmost=off
