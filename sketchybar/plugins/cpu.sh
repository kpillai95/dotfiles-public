#!/bin/bash

# Set CONFIG_DIR if not set
if [ -z "$CONFIG_DIR" ]; then
  CONFIG_DIR="$HOME/.config/sketchybar"
fi
source "$CONFIG_DIR/colors.sh"

CORE_COUNT=$(sysctl -n machdep.cpu.thread_count)
CPU_INFO=$(ps -eo pcpu,user)
CPU_SYS=$(echo "$CPU_INFO" | grep -v $(whoami) | sed "s/[^ 0-9\.]//g" | awk "{sum+=\$1} END {print sum/(100.0 * $CORE_COUNT)}")
CPU_USER=$(echo "$CPU_INFO" | grep $(whoami) | sed "s/[^ 0-9\.]//g" | awk "{sum+=\$1} END {print sum/(100.0 * $CORE_COUNT)}")

CPU_PERCENT="$(echo "$CPU_SYS $CPU_USER" | awk '{printf "%.0f\n", ($1 + $2)*100}')"

# Set color based on CPU usage
if [ "$CPU_PERCENT" -gt 50 ]; then
  # Above 50%: dark red
  CPU_COLOR=$CPU_CRITICAL
elif [ "$CPU_PERCENT" -gt 30 ]; then
  # Above 30%: orange/red
  CPU_COLOR=$CPU_HIGH
else
  # 30% or below: default background color (normal range)
  CPU_COLOR=$ITEM_BG_COLOR
fi

sketchybar --set $NAME label="$CPU_PERCENT%" background.color="$CPU_COLOR" background.drawing=on