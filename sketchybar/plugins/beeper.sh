#!/bin/bash

# Set CONFIG_DIR if not set
if [ -z "$CONFIG_DIR" ]; then
  CONFIG_DIR="$HOME/.config/sketchybar"
fi
source "$CONFIG_DIR/colors.sh"

# Debug mode - disable after confirming it works
DEBUG=false

debug_log() {
  if [ "$DEBUG" = "true" ]; then
    echo "[BEEPER DEBUG] $1" >> /tmp/beeper_debug.log 2>&1
  fi
}

# Get Beeper icon from icon map
BEEPER_ICON="$($CONFIG_DIR/plugins/icon_map_fn.sh "Beeper Desktop")"
if [ -z "$BEEPER_ICON" ] || [ "$BEEPER_ICON" = ":default:" ]; then
  BEEPER_ICON="$($CONFIG_DIR/plugins/icon_map_fn.sh "Beeper")"
fi
if [ -z "$BEEPER_ICON" ] || [ "$BEEPER_ICON" = ":default:" ]; then
  BEEPER_ICON=":beeper:"
fi
if [ -z "$BEEPER_ICON" ]; then
  # Final guaranteed visible fallback in the same app-font set.
  BEEPER_ICON=":todoist:"
fi

# Check if Beeper is running
BEEPER_RUNNING=false
if pgrep -x "Beeper Desktop" > /dev/null || pgrep -x "Beeper" > /dev/null; then
  BEEPER_RUNNING=true
  debug_log "Beeper is running"
else
  debug_log "Beeper is NOT running"
fi

UNREAD_COUNT="0"

# Method 1: Try to get badge count from Dock using AppleScript with AXStatusLabel
if [ "$BEEPER_RUNNING" = "true" ]; then
  # Method 1a: same approach as todoist/spark
  APPLE_SCRIPT_RESULT=""
  for attempt in 1 2; do
    APPLE_SCRIPT_RESULT=$(osascript -e '
tell application "System Events"
  try
    tell process "Dock"
      try
        set beeperTile to missing value
        try
          set beeperTile to UI element "Beeper Desktop" of list 1
        on error
          set beeperTile to UI element "Beeper" of list 1
        end try
        try
          set badgeVal to value of attribute "AXStatusLabel" of beeperTile
          if badgeVal is not missing value and badgeVal is not "" then
            return badgeVal as string
          else
            return ""
          end if
        on error
          return ""
        end try
      on error
        return ""
      end try
    end tell
  on error
    return ""
  end try
end tell
' 2>&1)

    if echo "$APPLE_SCRIPT_RESULT" | grep -qE '^[0-9]+$'; then
      debug_log "AppleScript attempt $attempt succeeded: '$APPLE_SCRIPT_RESULT'"
      break
    else
      debug_log "AppleScript attempt $attempt returned: '$APPLE_SCRIPT_RESULT'"
      if [ "$attempt" -eq 1 ]; then
        sleep 0.1
      fi
    fi
  done

  if echo "$APPLE_SCRIPT_RESULT" | grep -qE '^[0-9]+$'; then
    UNREAD_COUNT="$APPLE_SCRIPT_RESULT"
    debug_log "Successfully extracted count from AppleScript: $UNREAD_COUNT"
  elif [ -z "$APPLE_SCRIPT_RESULT" ] || [ "$APPLE_SCRIPT_RESULT" = "missing value" ] || [ "$APPLE_SCRIPT_RESULT" = "" ]; then
    UNREAD_COUNT="0"
    debug_log "Badge is empty/missing (no unread notifications), setting to 0"
  else
    # Direct query fallback
    debug_log "AppleScript returned unexpected value: '$APPLE_SCRIPT_RESULT', trying direct query"
    DIRECT_RESULT=$(osascript -e 'tell application "System Events" to tell process "Dock" to get value of attribute "AXStatusLabel" of UI element "Beeper Desktop" of list 1' 2>&1)
    debug_log "Direct query result: '$DIRECT_RESULT'"

    if echo "$DIRECT_RESULT" | grep -qE '^[0-9]+$'; then
      UNREAD_COUNT="$DIRECT_RESULT"
      debug_log "Direct query succeeded: $UNREAD_COUNT"
    elif [ -z "$DIRECT_RESULT" ] || [ "$DIRECT_RESULT" = "missing value" ]; then
      # Try fallback app name
      DIRECT_RESULT=$(osascript -e 'tell application "System Events" to tell process "Dock" to get value of attribute "AXStatusLabel" of UI element "Beeper" of list 1' 2>&1)
      if echo "$DIRECT_RESULT" | grep -qE '^[0-9]+$'; then
        UNREAD_COUNT="$DIRECT_RESULT"
      elif [ -n "$DIRECT_RESULT" ] && [ "$DIRECT_RESULT" != "missing value" ]; then
        # Non-numeric badge values (e.g., dots) still mean unread notifications.
        UNREAD_COUNT="1"
      else
        UNREAD_COUNT="0"
      fi
    else
      UNREAD_COUNT="0"
      debug_log "All queries failed, defaulting to 0"
    fi
  fi
fi

# Non-numeric but non-empty badge value means "has unread".
if ! [[ "$UNREAD_COUNT" =~ ^[0-9]+$ ]]; then
  if [ -n "$APPLE_SCRIPT_RESULT" ] && [ "$APPLE_SCRIPT_RESULT" != "missing value" ]; then
    UNREAD_COUNT="1"
  else
    UNREAD_COUNT="0"
  fi
fi

debug_log "Final UNREAD_COUNT: $UNREAD_COUNT"

# Display logic - ALWAYS show icon when Beeper is running, even if count is 0
if [ "$BEEPER_RUNNING" = "true" ]; then
  if [ "$UNREAD_COUNT" -gt 0 ]; then
    BEEPER_BG_COLOR=$BEEPER_UNREAD
    debug_log "Showing icon with unread notifications: $UNREAD_COUNT"
  else
    BEEPER_BG_COLOR=$ITEM_BG_COLOR
    debug_log "Showing icon with no unread notifications"
  fi

  sketchybar --set "$NAME" \
             icon="$BEEPER_ICON" \
             label="$UNREAD_COUNT" \
             drawing=on \
             icon.drawing=on \
             label.drawing=on \
             background.drawing=on \
             background.color=$BEEPER_BG_COLOR \
             icon.color=$ACCENT_COLOR \
             label.color=$ACCENT_COLOR \
             click_script="open -a 'Beeper Desktop'"
else
  debug_log "Beeper not running, hiding widget"
  sketchybar --set "$NAME" drawing=off
fi
