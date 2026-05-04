#!/bin/sh

# Set CONFIG_DIR if not set
if [ -z "$CONFIG_DIR" ]; then
  CONFIG_DIR="$HOME/.config/sketchybar"
fi
source "$CONFIG_DIR/colors.sh"

# Some events send additional information specific to the event in the $INFO
# variable. E.g. the front_app_switched event sends the name of the newly
# focused application in the $INFO variable:
# https://felixkratz.github.io/SketchyBar/config/events#events-and-scripting

if [ "$SENDER" = "front_app_switched" ]; then
  APP_NAME="$INFO"
  # Change display name for Spark Desktop
  if [ "$APP_NAME" = "Spark Desktop" ]; then
    DISPLAY_NAME="Spark"
  else
    DISPLAY_NAME="$APP_NAME"
  fi
  
  APP_ICON="$($CONFIG_DIR/plugins/icon_map_fn.sh "$APP_NAME")"
  
  sketchybar --set "$NAME" label="$DISPLAY_NAME" icon="$APP_ICON" \
             icon.color=$ORANGE_COLOR label.color=$ORANGE_COLOR
  
elif [ "$SENDER" = "system_woke" ]; then
  # On system wake, refresh the front app display
  sleep 0.08
  APP_NAME=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null || echo "")
  if [ -n "$APP_NAME" ]; then
    if [ "$APP_NAME" = "Spark Desktop" ]; then
      DISPLAY_NAME="Spark"
    else
      DISPLAY_NAME="$APP_NAME"
    fi
    APP_ICON="$($CONFIG_DIR/plugins/icon_map_fn.sh "$APP_NAME")"
    sketchybar --set "$NAME" label="$DISPLAY_NAME" icon="$APP_ICON" \
               icon.color=$ORANGE_COLOR label.color=$ORANGE_COLOR
  fi
fi
