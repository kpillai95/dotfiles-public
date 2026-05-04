#!/bin/bash

# Query Aerospace for workspaces and update sketchybar
# This replaces the space component with regular items that query Aerospace directly

# Set CONFIG_DIR if not set (when called directly)
if [ -z "$CONFIG_DIR" ]; then
  CONFIG_DIR="$HOME/.config/sketchybar"
fi

source "$CONFIG_DIR/colors.sh"
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

# Handle system_woke event specially - small delay so Aerospace is ready
if [ "$SENDER" = "system_woke" ]; then
  sleep 0.03
fi

# Workspaces shown in bar (requested order)
SPACE_SIDS=(1 2 3 4 8 9 10 C X Z)
PREV_WS_FILE="/tmp/sketchybar_prev_display_workspace"

# Workspace IDs are queried exactly as shown in the bar.
map_to_aerospace_sid() {
  echo "$1"
}

build_icon_strip_for_sid() {
  local sid="$1"
  local aerospace_sid
  local windows_json
  local app_names
  local icon_strip
  local app_name
  local app_icon

  aerospace_sid="$(map_to_aerospace_sid "$sid")"
  windows_json=$(aerospace list-windows --workspace "$aerospace_sid" --json 2>/dev/null || echo "[]")
  app_names=$(echo "$windows_json" | jq -r '.[]."app-name"' 2>/dev/null | sort -u || echo "")

  icon_strip=""
  if [ -n "$app_names" ] && [ "$app_names" != "" ]; then
    while IFS= read -r app_name; do
      if [ -n "$app_name" ] && [ "$app_name" != "" ] && [ "$app_name" != "null" ]; then
        app_icon="$($CONFIG_DIR/plugins/icon_map_fn.sh "$app_name")"
        if [ -n "$icon_strip" ]; then
          icon_strip+=" "
        fi
        icon_strip+="$app_icon"
      fi
    done <<< "$app_names"
  fi

  echo "$icon_strip"
}

refresh_label_for_sid() {
  local sid="$1"
  local icon_strip
  icon_strip="$(build_icon_strip_for_sid "$sid")"
  sketchybar --set "space.$sid" \
             drawing=on \
             icon.drawing=on \
             label.drawing=on \
             label="$icon_strip" \
             background.drawing=on 2>/dev/null
}

# Focus from event first (shared with per-space item scripts); CLI only as fallback.
# shellcheck source=/dev/null
source "$CONFIG_DIR/plugins/aerospace_focus_from_event.sh"

if [ -z "$current_workspace" ]; then
  current_workspace=$(aerospace list-workspaces --focused 2>/dev/null | head -1 | tr -d '"' | xargs || echo "")
fi
# Second query + sleep helps stale focus on wake/timer; workspace_change should never block here.
if [ -z "$current_workspace" ] && [ "$SENDER" != "aerospace_workspace_change" ]; then
  sleep 0.05
  current_workspace=$(aerospace list-workspaces --focused 2>/dev/null | head -1 | tr -d '"' | xargs || echo "")
fi

current_display_workspace="$current_workspace"

# If focus couldn't be resolved for this run, keep previous highlight instead of dropping red.
if [ -z "$current_display_workspace" ] && [ -f "$PREV_WS_FILE" ]; then
  current_display_workspace="$(<"$PREV_WS_FILE")"
fi

# workspace_monitor on workspace_change: only refresh app icons (async). Each space.$sid item
# runs its own script in parallel for highlight — same idea as native space + $SELECTED (Josean blog).
if [ "$SENDER" = "aerospace_workspace_change" ] && [ "$NAME" = "workspace_monitor" ]; then
  if [ -n "$current_display_workspace" ]; then
    prev_display_workspace=""
    if [ -f "$PREV_WS_FILE" ]; then
      prev_display_workspace="$(<"$PREV_WS_FILE")"
    fi
    echo "$current_display_workspace" > "$PREV_WS_FILE" 2>/dev/null || true
    (
      refresh_label_for_sid "$current_display_workspace"
      if [ -n "$prev_display_workspace" ] && [ "$prev_display_workspace" != "$current_display_workspace" ]; then
        refresh_label_for_sid "$prev_display_workspace"
      fi
    ) &
  fi
  exit 0
fi

# Phase 1: highlight before window queries (routine, timer, system_woke, manual run).
apply_highlight_for_sid() {
  local sid="$1"
  if [ "$current_display_workspace" = "$sid" ]; then
    sketchybar --set "space.$sid" \
               background.color=$CURRENT_SPACE_BG \
               label.color=$CURRENT_SPACE_TEXT \
               icon.color=$CURRENT_SPACE_TEXT 2>/dev/null
  else
    sketchybar --set "space.$sid" \
               background.color=$SPACE_BG_COLOR \
               label.color=$SPACE_TEXT_COLOR \
               icon.color=$SPACE_TEXT_COLOR 2>/dev/null
  fi
}

for sid in "${SPACE_SIDS[@]}"; do
  apply_highlight_for_sid "$sid"
done

# Process each workspace
# Query windows in parallel to avoid long serial delays across all spaces.
TMP_DIR="$(mktemp -d /tmp/sketchybar_ws.XXXXXX 2>/dev/null || echo "")"
cleanup_tmp() {
  [ -n "$TMP_DIR" ] && rm -rf "$TMP_DIR" 2>/dev/null || true
}
trap cleanup_tmp EXIT

for sid in "${SPACE_SIDS[@]}"; do
  aerospace_sid="$(map_to_aerospace_sid "$sid")"
  if [ -n "$TMP_DIR" ]; then
    (
      aerospace list-windows --workspace "$aerospace_sid" --json > "$TMP_DIR/$sid.json" 2>/dev/null || echo "[]" > "$TMP_DIR/$sid.json"
    ) &
  fi
done
[ -n "$TMP_DIR" ] && wait

for sid in "${SPACE_SIDS[@]}"; do
  if [ -n "$TMP_DIR" ] && [ -f "$TMP_DIR/$sid.json" ]; then
    windows_json=$(cat "$TMP_DIR/$sid.json" 2>/dev/null || echo "[]")
  else
    aerospace_sid="$(map_to_aerospace_sid "$sid")"
    windows_json=$(aerospace list-windows --workspace "$aerospace_sid" --json 2>/dev/null || echo "[]")
  fi
  
  app_names=$(echo "$windows_json" | jq -r '.[]."app-name"' 2>/dev/null | sort -u || echo "")

  icon_strip=""
  if [ -n "$app_names" ] && [ "$app_names" != "" ]; then
    while IFS= read -r app_name; do
      if [ -n "$app_name" ] && [ "$app_name" != "" ] && [ "$app_name" != "null" ]; then
        app_icon="$($CONFIG_DIR/plugins/icon_map_fn.sh "$app_name")"
        if [ -n "$icon_strip" ]; then
          icon_strip+=" "
        fi
        icon_strip+="$app_icon"
      fi
    done <<< "$app_names"
  fi

  # Always keep requested workspaces visible.
  sketchybar --set "space.$sid" \
             drawing=on \
             icon.drawing=on \
             label.drawing=on \
             label="$icon_strip" \
             background.drawing=on 2>/dev/null
done

echo "$current_display_workspace" > "$PREV_WS_FILE" 2>/dev/null || true
