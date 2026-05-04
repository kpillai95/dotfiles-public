#!/bin/bash

CACHE_FILE="/tmp/sketchybar_claude_pct.txt"
TOKEN_FILE="/tmp/sketchybar_claude_token.txt"
BACKOFF_FILE="/tmp/sketchybar_claude_backoff.txt"

# Treat right-click same as forced refresh
[ "$SENDER" = "mouse.right_clicked" ] && FORCE=1

# Show cached values immediately (never show placeholder)
if [ -f "$CACHE_FILE" ]; then
  read CPCT WPCT < "$CACHE_FILE"
  sketchybar --set claude_usage label="${CPCT}% | ${WPCT}%"
fi

# Skip API call if cache is fresh (< 100s)
CACHE_AGE=9999
[ -f "$CACHE_FILE" ] && CACHE_AGE=$(( $(date +%s) - $(stat -f %m "$CACHE_FILE") ))
if [ "$CACHE_AGE" -lt 100 ] && [ "$FORCE" != "1" ] && [ "$SENDER" != "system_woke" ]; then
  exit 0
fi

# Respect backoff after 429 — skip for 90s unless forced
if [ -f "$BACKOFF_FILE" ] && [ "$FORCE" != "1" ]; then
  backoff_age=$(( $(date +%s) - $(stat -f %m "$BACKOFF_FILE") ))
  if [ "$backoff_age" -lt 90 ]; then
    exit 0
  fi
fi

# On forced refresh: clear backoff so we always try
[ "$FORCE" = "1" ] && rm -f "$BACKOFF_FILE"

# On wake, let network settle first
[ "$SENDER" = "system_woke" ] && sleep 10

get_token() {
  if [ -f "$TOKEN_FILE" ]; then
    local age=$(( $(date +%s) - $(stat -f %m "$TOKEN_FILE" 2>/dev/null || echo 0) ))
    if [ "$age" -lt 1200 ]; then
      cat "$TOKEN_FILE"
      return 0
    fi
  fi
  local token
  token=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null \
    | python3 -c "import json,sys; print(json.loads(sys.stdin.read())['claudeAiOauth']['accessToken'])" 2>/dev/null)
  if [ -n "$token" ]; then
    echo "$token" > "$TOKEN_FILE"
    chmod 600 "$TOKEN_FILE"
    echo "$token"
  fi
}

fetch_usage() {
  local token="$1"
  local response http_code body
  response=$(curl -sf -w "\n%{http_code}" "https://api.anthropic.com/api/oauth/usage" \
    -H "Authorization: Bearer $token" \
    -H "anthropic-beta: oauth-2025-04-20" \
    -H "User-Agent: claude-code/2.1.112" \
    -H "Accept: application/json" \
    --max-time 10 2>/dev/null)
  http_code=$(echo "$response" | tail -1)
  body=$(echo "$response" | head -1)
  case "$http_code" in
    401) rm -f "$TOKEN_FILE"; echo "EXPIRED" ;;
    429) echo "RATELIMIT" ;;
    *)   echo "$body" ;;
  esac
}

TOKEN=$(get_token)
if [ -z "$TOKEN" ]; then
  sketchybar --set claude_usage label="auth?"
  exit 0
fi

RESULT=$(fetch_usage "$TOKEN")

# On 401 or 429: clear cached token and retry once with fresh keychain token
if [ "$RESULT" = "EXPIRED" ] || [ "$RESULT" = "RATELIMIT" ]; then
  rm -f "$TOKEN_FILE"
  TOKEN=$(get_token)
  [ -n "$TOKEN" ] && RESULT=$(fetch_usage "$TOKEN")
fi

# If still failing after fresh token: backoff and wait
if [ "$RESULT" = "RATELIMIT" ] || [ -z "$RESULT" ] || [ "$RESULT" = "EXPIRED" ]; then
  touch "$BACKOFF_FILE"
  exit 0
fi

read CPCT WPCT <<< "$(USAGE_JSON="$RESULT" python3 << 'PYEOF'
import json, os
from datetime import datetime, timezone

d = json.loads(os.environ['USAGE_JSON'])
now = datetime.now(timezone.utc)

def resolve(key):
    block = d.get(key, {})
    utilization = block.get('utilization') or 0
    resets_at_str = block.get('resets_at')
    if resets_at_str:
        resets_at = datetime.fromisoformat(resets_at_str)
        if now > resets_at:
            return 0
    return int(utilization)

print(resolve('five_hour'), resolve('seven_day'))
PYEOF
)"

CPCT=${CPCT:-0}
WPCT=${WPCT:-0}
echo "$CPCT $WPCT" > "$CACHE_FILE"
rm -f "$BACKOFF_FILE"
sketchybar --set claude_usage label="${CPCT}% | ${WPCT}%"
