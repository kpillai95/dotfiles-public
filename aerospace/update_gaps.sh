#!/bin/bash
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

REAL_HOME=$(eval echo ~"$(id -un)")
TOML="$REAL_HOME/.config/aerospace/aerospace.toml"

if [ ! -f "$TOML" ]; then
    exit 1
fi

# AppleClamshellState=Yes means lid is closed (clamshell mode) → 40px gap needed
# AppleClamshellState=No  means lid is open (laptop or dual-display) → 3px (notch handles rest)
CLAMSHELL=$(ioreg -r -k AppleClamshellState 2>/dev/null \
  | grep -o '"AppleClamshellState" = [A-Za-z]*' | grep -o '[A-Za-z]*$')

if [ "$CLAMSHELL" = "Yes" ]; then
    NEW_TOP=40
else
    NEW_TOP=3
fi

CURRENT=$(grep 'outer\.top' "$TOML" | grep -o '[0-9]*$' | tr -d '[:space:]')
if [ "$CURRENT" = "$NEW_TOP" ]; then
    exit 0
fi

python3 -c "
import re, sys
path, new_top = sys.argv[1], sys.argv[2]
content = open(path).read()
updated = re.sub(r'outer\.top\s*=\s*\d+', 'outer.top        = ' + new_top, content)
open(path, 'w').write(updated)
" "$TOML" "$NEW_TOP"

echo "$(date): set outer.top=$NEW_TOP (clamshell=$CLAMSHELL)" >> /tmp/display-watcher.log

aerospace reload-config 2>/dev/null || true
