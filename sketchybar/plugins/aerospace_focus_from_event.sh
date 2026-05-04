# Sourced by aerospace scripts: set current_workspace from trigger env only (no CLI).
# shellcheck shell=bash
current_workspace=""
if [ -n "$INFO" ]; then
  case "$INFO" in
    *FOCUSED_WORKSPACE=*)
      current_workspace="${INFO#*FOCUSED_WORKSPACE=}"
      current_workspace="${current_workspace%% *}"
      current_workspace=$(echo "$current_workspace" | tr -d '"' | xargs)
      ;;
    *)
      if [ "$SENDER" = "aerospace_workspace_change" ]; then
        current_workspace=$(echo "$INFO" | tr -d '"' | xargs)
      fi
      ;;
  esac
fi
if [ -z "$current_workspace" ] && [ -n "$FOCUSED_WORKSPACE" ]; then
  current_workspace=$(echo "$FOCUSED_WORKSPACE" | tr -d '"' | xargs)
fi
if [ -z "$current_workspace" ] && [ -n "$AEROSPACE_FOCUSED_WORKSPACE" ]; then
  current_workspace=$(echo "$AEROSPACE_FOCUSED_WORKSPACE" | tr -d '"' | xargs)
fi
