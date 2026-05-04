#!/bin/bash

# Test script to check if we can read Spark's badge
# Run this manually to see what methods work

echo "Testing Spark badge detection methods..."
echo ""

# Check if Spark is running
if pgrep -x "Spark Desktop" > /dev/null; then
  echo "✓ Spark Desktop is running"
else
  echo "✗ Spark Desktop is NOT running"
  exit 1
fi

echo ""
echo "Method 1: Direct badge property access"
BADGE1=$(osascript -e '
tell application "System Events"
  try
    set sparkProcess to first application process whose name is "Spark Desktop"
    try
      return badge value of sparkProcess as string
    on error errMsg
      return "ERROR: " & errMsg
    end try
  on error errMsg
    return "ERROR: " & errMsg
  end try
end tell
' 2>&1)
echo "Result: $BADGE1"

echo ""
echo "Method 2: Using bundle identifier"
BADGE2=$(osascript -e '
tell application "System Events"
  try
    set sparkProcess to first application process whose bundle identifier is "com.readdle.SparkDesktop.appstore"
    try
      return badge value of sparkProcess as string
    on error errMsg
      return "ERROR: " & errMsg
    end try
  on error errMsg
    return "ERROR: " & errMsg
  end try
end tell
' 2>&1)
echo "Result: $BADGE2"

echo ""
echo "Method 3: Try accessing via Dock"
BADGE3=$(osascript -e '
tell application "System Events"
  try
    tell process "Dock"
      try
        set sparkTile to UI element "Spark Desktop" of list 1
        try
          return value of attribute "AXStatusLabel" of sparkTile as string
        on error
          return "AXStatusLabel not available"
        end try
      on error errMsg
        return "ERROR: " & errMsg
      end try
    end tell
  on error errMsg
    return "ERROR: " & errMsg
  end try
end tell
' 2>&1)
echo "Result: $BADGE3"

echo ""
echo "---"
echo "If all methods return 0 or errors, you may need to:"
echo "1. Grant Accessibility permissions to Terminal/SketchyBar in System Settings > Privacy & Security > Accessibility"
echo "2. Check if Spark's badge is actually showing in the Dock"
echo "3. Try restarting Spark after granting permissions"
