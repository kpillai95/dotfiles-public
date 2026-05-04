#!/bin/bash

# Helper script to get Dock badge using a different approach
# This uses osascript but with better error handling

APP_NAME="$1"
BUNDLE_ID="$2"

if [ -z "$APP_NAME" ] && [ -z "$BUNDLE_ID" ]; then
  echo "0"
  exit 0
fi

# Try to get badge using a simpler AppleScript that might work better
BADGE=$(osascript <<EOF 2>/dev/null
tell application "System Events"
  try
    -- Try to get badge from the application process directly
    if "$BUNDLE_ID" is not "" then
      set appProc to first application process whose bundle identifier is "$BUNDLE_ID"
    else if "$APP_NAME" is not "" then
      set appProc to first application process whose name is "$APP_NAME"
    else
      return "0"
    end if
    
    try
      set badgeVal to badge value of appProc
      if badgeVal is not missing value and badgeVal is not "" then
        return badgeVal as string
      end if
    end try
    
    return "0"
  on error
    return "0"
  end try
end tell
EOF
)

if [ -z "$BADGE" ]; then
  echo "0"
else
  echo "$BADGE"
fi
