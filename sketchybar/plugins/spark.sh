#!/bin/bash

# Set CONFIG_DIR if not set
if [ -z "$CONFIG_DIR" ]; then
  CONFIG_DIR="$HOME/.config/sketchybar"
fi
source "$CONFIG_DIR/colors.sh"

# Debug mode - keep off for battery/perf
DEBUG=false

debug_log() {
  if [ "$DEBUG" = "true" ]; then
    echo "[SPARK DEBUG] $1" >> /tmp/spark_debug.log 2>&1
  fi
}

# Get Spark icon from icon map
SPARK_ICON="$($CONFIG_DIR/plugins/icon_map_fn.sh "Spark Desktop")"

# Check if Spark is running
SPARK_RUNNING=false
if pgrep -x "Spark Desktop" > /dev/null; then
  SPARK_RUNNING=true
  debug_log "Spark Desktop is running"
else
  debug_log "Spark Desktop is NOT running"
fi

UNREAD_COUNT="0"

# Method 1: Try to get badge count from Dock using AppleScript with AXStatusLabel
if [ "$SPARK_RUNNING" = "true" ]; then
  # Method 1a: Use the exact working method from test_spark_badge.sh (Method 3)
  # This method works from Terminal - use exact same syntax
  # Try multiple times with small delay to catch badge updates (Spark may update badge with delay)
  APPLE_SCRIPT_RESULT=""
  for attempt in 1 2; do
    APPLE_SCRIPT_RESULT=$(osascript -e '
tell application "System Events"
  try
    tell process "Dock"
      try
        set sparkTile to UI element "Spark Desktop" of list 1
        try
          set badgeVal to value of attribute "AXStatusLabel" of sparkTile
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
      # Small delay before retry to allow Spark to update badge
      if [ "$attempt" -eq 1 ]; then
        sleep 0.1
      fi
    fi
  done
  
  # Extract just the number if it's a valid number
  # Empty string or "missing value" means 0 unread emails
  if echo "$APPLE_SCRIPT_RESULT" | grep -qE '^[0-9]+$'; then
    UNREAD_COUNT="$APPLE_SCRIPT_RESULT"
    debug_log "Successfully extracted count from AppleScript: $UNREAD_COUNT"
  elif [ -z "$APPLE_SCRIPT_RESULT" ] || [ "$APPLE_SCRIPT_RESULT" = "missing value" ] || [ "$APPLE_SCRIPT_RESULT" = "" ]; then
    # Empty or missing value means 0 unread (badge is not showing)
    UNREAD_COUNT="0"
    debug_log "Badge is empty/missing (no unread emails), setting to 0"
  else
    # Try one more direct query as fallback
    debug_log "AppleScript returned unexpected value: '$APPLE_SCRIPT_RESULT', trying direct query"
    DIRECT_RESULT=$(osascript -e 'tell application "System Events" to tell process "Dock" to get value of attribute "AXStatusLabel" of UI element "Spark Desktop" of list 1' 2>&1)
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
  
  # Method 1b and 1c are not needed since Method 1a (Dock AXStatusLabel) works
  # Keeping them as fallbacks but they're less reliable
  
  # Method 2: Try using the helper script
  if [ "$UNREAD_COUNT" = "0" ] || [ -z "$UNREAD_COUNT" ]; then
    if [ -f "$CONFIG_DIR/plugins/get_dock_badge.sh" ]; then
      HELPER_COUNT=$("$CONFIG_DIR/plugins/get_dock_badge.sh" "Spark Desktop" "com.readdle.SparkDesktop.appstore" 2>/dev/null)
      if [ -n "$HELPER_COUNT" ] && [[ "$HELPER_COUNT" =~ ^[0-9]+$ ]] && [ "$HELPER_COUNT" != "0" ]; then
        UNREAD_COUNT="$HELPER_COUNT"
        debug_log "Method 2 (helper script) returned: $UNREAD_COUNT"
      fi
    fi
  fi
  
  # Method 3: Try reading from UserNotifications database (macOS stores badge counts here)
  if [ "$UNREAD_COUNT" = "0" ] || [ -z "$UNREAD_COUNT" ]; then
    # Check the notification center database for Spark's badge
    NOTIFICATION_DB="$HOME/Library/Application Support/NotificationCenter/db2/db"
    if [ -f "$NOTIFICATION_DB" ] && command -v sqlite3 >/dev/null 2>&1; then
      # Try to query for Spark's badge (this is a complex database structure)
      # The badge might be stored in the app_info table
      DB_COUNT=$(sqlite3 "$NOTIFICATION_DB" "
        SELECT COUNT(*) 
        FROM app_info 
        WHERE bundle_id = 'com.readdle.SparkDesktop.appstore'
        LIMIT 1;
      " 2>/dev/null | head -1)
      # Note: This might not work as the schema is private, but worth trying
    fi
  fi
  
  # Method 3: Try querying Spark's preferences/plist files
  if [ "$UNREAD_COUNT" = "0" ] || [ -z "$UNREAD_COUNT" ]; then
    # Check various plist locations
    PLIST_PATHS=(
      "$HOME/Library/Preferences/com.readdle.SparkDesktop.plist"
      "$HOME/Library/Containers/com.readdle.SparkDesktop.appstore/Data/Library/Preferences/com.readdle.SparkDesktop.plist"
    )
    
    for plist_path in "${PLIST_PATHS[@]}"; do
      if [ -f "$plist_path" ]; then
        BADGE_COUNT=$(defaults read "${plist_path%.plist}" badgeCount 2>/dev/null || echo "")
        if [ -n "$BADGE_COUNT" ] && [[ "$BADGE_COUNT" =~ ^[0-9]+$ ]] && [ "$BADGE_COUNT" != "0" ]; then
          UNREAD_COUNT="$BADGE_COUNT"
          break
        fi
      fi
    done
  fi
fi

# Ensure UNREAD_COUNT is a valid number
if ! [[ "$UNREAD_COUNT" =~ ^[0-9]+$ ]]; then
  UNREAD_COUNT="0"
fi

debug_log "Final UNREAD_COUNT: $UNREAD_COUNT"

# Display logic - ALWAYS show icon when Spark is running, even if count is 0
if [ "$SPARK_RUNNING" = "true" ]; then
  debug_log "Setting display: UNREAD_COUNT=$UNREAD_COUNT, SPARK_ICON=$SPARK_ICON"
  
  # Set background color based on unread count
  if [ "$UNREAD_COUNT" -gt 0 ]; then
    # Has unread emails: dark blue background
    SPARK_BG_COLOR=$SPARK_UNREAD
    debug_log "Showing icon with unread emails: $UNREAD_COUNT (dark blue background)"
  else
    # No unread emails: default background
    SPARK_BG_COLOR=$ITEM_BG_COLOR
    debug_log "Showing icon with no unread emails (default background)"
  fi
  
  # Always show icon and count (including 0)
  sketchybar --set "$NAME" \
             icon="$SPARK_ICON" \
             label="$UNREAD_COUNT" \
             drawing=on \
             icon.drawing=on \
             label.drawing=on \
             background.drawing=on \
             background.color=$SPARK_BG_COLOR \
             icon.color=$ACCENT_COLOR \
             label.color=$ACCENT_COLOR \
             click_script="open -a 'Spark Desktop'" 2>&1 | while read line; do debug_log "sketchybar output: $line"; done
else
  # Hide if Spark is not running
  debug_log "Spark not running, hiding widget"
  sketchybar --set "$NAME" drawing=off 2>&1 | while read line; do debug_log "sketchybar output: $line"; done
fi
