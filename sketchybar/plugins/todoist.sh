#!/bin/bash

# Set CONFIG_DIR if not set
if [ -z "$CONFIG_DIR" ]; then
  CONFIG_DIR="$HOME/.config/sketchybar"
fi
source "$CONFIG_DIR/colors.sh"

# Debug mode - set to true to enable logging
# Disable after confirming it works
DEBUG=false

debug_log() {
  if [ "$DEBUG" = "true" ]; then
    echo "[TODOIST DEBUG] $1" >> /tmp/todoist_debug.log 2>&1
  fi
}

# Get Todoist icon from icon map
TODOIST_ICON="$($CONFIG_DIR/plugins/icon_map_fn.sh "Todoist")"

# Check if Todoist is running
TODOIST_RUNNING=false
if pgrep -x "Todoist" > /dev/null; then
  TODOIST_RUNNING=true
  debug_log "Todoist is running"
else
  debug_log "Todoist is NOT running"
fi

UNREAD_COUNT="0"

# Method 1: Try to get badge count from Dock using AppleScript with AXStatusLabel
if [ "$TODOIST_RUNNING" = "true" ]; then
  # Method 1a: Use the exact working method from test_spark_badge.sh (Method 3)
  # This method works from Terminal - use exact same syntax
  # Try multiple times with small delay to catch badge updates
  APPLE_SCRIPT_RESULT=""
  for attempt in 1 2; do
    APPLE_SCRIPT_RESULT=$(osascript -e '
tell application "System Events"
  try
    tell process "Dock"
      try
        set todoistTile to UI element "Todoist" of list 1
        try
          set badgeVal to value of attribute "AXStatusLabel" of todoistTile
          if badgeVal is not missing value and badgeVal is not "" then
            return badgeVal as string
          else
            return ""
          end if
        on error
          return ""
        end try
      on error errMsg
        return ""
      end try
    end tell
  on error errMsg
    return ""
  end try
end tell
' 2>&1)
    
    # If we got a valid number, use it
    if echo "$APPLE_SCRIPT_RESULT" | grep -qE '^[0-9]+$'; then
      debug_log "AppleScript attempt $attempt succeeded: '$APPLE_SCRIPT_RESULT'"
      break
    else
      debug_log "AppleScript attempt $attempt returned: '$APPLE_SCRIPT_RESULT'"
      # Small delay before retry to allow Todoist to update badge
      if [ "$attempt" -eq 1 ]; then
        sleep 0.1
      fi
    fi
  done
  
  # Extract just the number if it's a valid number
  # Empty string or "missing value" means 0 unread notifications
  if echo "$APPLE_SCRIPT_RESULT" | grep -qE '^[0-9]+$'; then
    UNREAD_COUNT="$APPLE_SCRIPT_RESULT"
    debug_log "Successfully extracted count from AppleScript: $UNREAD_COUNT"
  elif [ -z "$APPLE_SCRIPT_RESULT" ] || [ "$APPLE_SCRIPT_RESULT" = "missing value" ] || [ "$APPLE_SCRIPT_RESULT" = "" ]; then
    # Empty or missing value means 0 unread (badge is not showing)
    UNREAD_COUNT="0"
    debug_log "Badge is empty/missing (no unread notifications), setting to 0"
  else
    # Try one more direct query as fallback
    debug_log "AppleScript returned unexpected value: '$APPLE_SCRIPT_RESULT', trying direct query"
    DIRECT_RESULT=$(osascript -e 'tell application "System Events" to tell process "Dock" to get value of attribute "AXStatusLabel" of UI element "Todoist" of list 1' 2>&1)
    debug_log "Direct query result: '$DIRECT_RESULT'"
    
    if echo "$DIRECT_RESULT" | grep -qE '^[0-9]+$'; then
      UNREAD_COUNT="$DIRECT_RESULT"
      debug_log "Direct query succeeded: $UNREAD_COUNT"
    elif [ -z "$DIRECT_RESULT" ] || [ "$DIRECT_RESULT" = "missing value" ]; then
      UNREAD_COUNT="0"
      debug_log "Direct query also empty, setting to 0"
    else
      UNREAD_COUNT="0"
      debug_log "All queries failed, defaulting to 0"
    fi
  fi
  
  debug_log "Method 1a (AXStatusLabel from Dock) final result: $UNREAD_COUNT"
fi

# Ensure UNREAD_COUNT is a valid number
if ! [[ "$UNREAD_COUNT" =~ ^[0-9]+$ ]]; then
  UNREAD_COUNT="0"
fi

debug_log "Final UNREAD_COUNT: $UNREAD_COUNT"

# Display logic - ALWAYS show icon when Todoist is running, even if count is 0
if [ "$TODOIST_RUNNING" = "true" ]; then
  debug_log "Setting display: UNREAD_COUNT=$UNREAD_COUNT, TODOIST_ICON=$TODOIST_ICON"
  
  # Set background color based on unread count
  if [ "$UNREAD_COUNT" -gt 0 ]; then
    # Has unread notifications: red/orange background (#EE4E39)
    TODOIST_BG_COLOR=$TODOIST_UNREAD
    debug_log "Showing icon with unread notifications: $UNREAD_COUNT (red/orange background)"
  else
    # No unread notifications: default background
    TODOIST_BG_COLOR=$ITEM_BG_COLOR
    debug_log "Showing icon with no unread notifications (default background)"
  fi
  
  # Always show icon and count (including 0)
  sketchybar --set "$NAME" \
             icon="$TODOIST_ICON" \
             label="$UNREAD_COUNT" \
             drawing=on \
             icon.drawing=on \
             label.drawing=on \
             background.drawing=on \
             background.color=$TODOIST_BG_COLOR \
             icon.color=$ACCENT_COLOR \
             label.color=$ACCENT_COLOR \
             click_script="open -a 'Todoist'" 2>&1 | while read line; do debug_log "sketchybar output: $line"; done
else
  # Hide if Todoist is not running
  debug_log "Todoist not running, hiding widget"
  sketchybar --set "$NAME" drawing=off 2>&1 | while read line; do debug_log "sketchybar output: $line"; done
fi
