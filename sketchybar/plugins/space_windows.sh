#!/bin/bash

if [ "$SENDER" = "space_windows_change" ]; then
  space="$(echo "$INFO" | jq -r '.space')"
  apps="$(echo "$INFO" | jq -r '.apps | keys[]')"

  # Build icon strip from apps
  icon_strip=""
  if [ -n "${apps}" ] && [ "${apps}" != "" ]; then
    while read -r app
    do
      if [ -n "$app" ] && [ "$app" != "" ]; then
        app_icon="$($CONFIG_DIR/plugins/icon_map_fn.sh "$app")"
        if [ -n "$icon_strip" ]; then
          icon_strip+=" "
        fi
        icon_strip+="$app_icon"
      fi
    done <<< "${apps}"
  fi
  
  # Update the space label with app icons
  # The space component will automatically show/hide based on whether it has windows
  sketchybar --set space.$space label="$icon_strip"
fi

