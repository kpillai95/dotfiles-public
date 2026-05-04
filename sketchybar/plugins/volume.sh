#!/bin/sh

# The volume_change event supplies a $INFO variable in which the current volume
# percentage is passed to the script.

update_volume() {
  VOLUME="$1"

  case "$VOLUME" in
    [6-9][0-9]|100) ICON="􀊩"
    ;;
    [3-5][0-9]) ICON="􀊥"
    ;;
    [1-9]|[1-2][0-9]) ICON="􀊡"
    ;;
    *) ICON="􀊣"
  esac

  sketchybar --set "$NAME" icon="$ICON" label="$VOLUME%"
}

if [ "$SENDER" = "volume_change" ]; then
  update_volume "$INFO"
elif [ "$SENDER" = "system_woke" ]; then
  # On system wake, query the current volume and update
  VOLUME=$(osascript -e "output volume of (get volume settings)" 2>/dev/null || echo "0")
  if [ -n "$VOLUME" ]; then
    update_volume "$VOLUME"
  fi
fi
