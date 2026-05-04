#!/bin/bash

# Set CONFIG_DIR if not set
if [ -z "$CONFIG_DIR" ]; then
  CONFIG_DIR="$HOME/.config/sketchybar"
fi
source "$CONFIG_DIR/colors.sh"

# Get disk usage information
# Shows available disk space in GB (e.g., "73.97 GB")
# Uses diskutil to get physical disk info that matches System Settings

# Get the physical disk identifier from the root filesystem
# Extract disk number (e.g., /dev/disk3s5 -> disk3)
ROOT_DEVICE=$(df / | tail -1 | awk '{print $1}')
PHYSICAL_DISK=$(echo "$ROOT_DEVICE" | sed 's|/dev/||' | sed 's/s[0-9].*$//')

# Try to get disk info using diskutil (more accurate, matches System Settings)
DISK_INFO=$(diskutil info "$PHYSICAL_DISK" 2>/dev/null)

if [ -n "$DISK_INFO" ] && [ "$DISK_INFO" != "" ]; then
  # Extract free space from diskutil output
  # Look for "Volume Free Space" which includes purgeable space (matches System Settings)
  AVAILABLE=$(echo "$DISK_INFO" | grep -i "Volume Free Space" | awk -F'[()]' '{print $2}' | sed 's/^ *//' | head -1)
  
  # If that format doesn't work, try extracting bytes and converting
  if [ -z "$AVAILABLE" ] || [ "$AVAILABLE" = "" ]; then
    # Try to get the free space line and parse it
    FREE_LINE=$(echo "$DISK_INFO" | grep -i "Volume Free Space")
    if [ -n "$FREE_LINE" ]; then
      # Extract the human-readable part (e.g., "73.97 GB (73,970,000,000 bytes)")
      AVAILABLE=$(echo "$FREE_LINE" | awk -F'[()]' '{print $2}' | awk '{print $1, $2}')
    fi
  fi
fi

# Fallback to df if diskutil fails or doesn't provide the right format
# Use -H (capital H) for decimal units (GB) instead of -h (binary GiB)
if [ -z "$AVAILABLE" ] || [ "$AVAILABLE" = "" ]; then
  if [ -d "/System/Volumes/Data" ]; then
    DISK_INFO=$(df -H /System/Volumes/Data | tail -1)
  else
    DISK_INFO=$(df -H / | tail -1)
  fi
  AVAILABLE=$(echo "$DISK_INFO" | awk '{print $4}')
fi

# Extract numeric value from AVAILABLE (e.g., "73.97 GB" -> 73.97)
AVAILABLE_NUM=$(echo "$AVAILABLE" | grep -oE '[0-9]+\.?[0-9]*' | head -1)

# Set color based on available space
# If available space is below 45 GB, show dark red
if [ -n "$AVAILABLE_NUM" ]; then
  # Compare as floating point (using awk for comparison, more reliable than bc)
  AVAILABLE_INT=$(echo "$AVAILABLE_NUM" | awk '{printf "%.0f", $1}')
  if [ "$AVAILABLE_INT" -lt 45 ]; then
    DISK_COLOR=$MEMORY_LOW
  else
    # 45 GB or above: default background color (normal range)
    DISK_COLOR=$ITEM_BG_COLOR
  fi
else
  DISK_COLOR=$ITEM_BG_COLOR
fi

# Set the label with background color
sketchybar --set "$NAME" label="$AVAILABLE" background.color="$DISK_COLOR" background.drawing=on

