#!/bin/sh

# Set CONFIG_DIR if not set
if [ -z "$CONFIG_DIR" ]; then
  CONFIG_DIR="$HOME/.config/sketchybar"
fi
source "$CONFIG_DIR/colors.sh"

PERCENTAGE="$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)"
CHARGING="$(pmset -g batt | grep 'AC Power')"

if [ "$PERCENTAGE" = "" ]; then
  exit 0
fi

# Set icon and background color based on battery percentage
# 70-100% = Battery High, 50-70% = Battery Medium, 40-50% = Battery Low, below 40% = Critical
case "${PERCENTAGE}" in
  [7-9][0-9]|100) 
    ICON="􀛨"
    BG_COLOR=$BATTERY_HIGH
  ;;
  5[0-9]|6[0-9]) 
    ICON="􀺸"
    BG_COLOR=$BATTERY_MEDIUM
  ;;
  4[0-9]) 
    ICON="􀺶"
    BG_COLOR=$BATTERY_LOW
  ;;
  [1-3][0-9]) 
    ICON="􀛩"
    BG_COLOR=$BATTERY_CRITICAL
  ;;
  [0-9]) 
    ICON="􀛪"
    BG_COLOR=$BATTERY_CRITICAL
    ;;
esac

if [[ "$CHARGING" != "" ]]; then
  ICON="􀢋"
  # Use green background when charging
  BG_COLOR=$BATTERY_HIGH
fi

# The item invoking this script (name $NAME) will get its icon, label, and background
# updated with the current battery status
sketchybar --set "$NAME" icon.drawing=off label="${PERCENTAGE}%" background.color="$BG_COLOR" background.drawing=on
