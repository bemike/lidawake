#!/bin/bash
# While SleepDisabled is on: when lid closes, blank the display (system stays awake).
PIDFILE="${TMPDIR:-/tmp}/lidawake-display-watch.pid"
echo $$ > "$PIDFILE"
closed=0
while true; do
  state=$(ioreg -r -k AppleClamshellState -d 4 2>/dev/null | awk -F'= ' '/"AppleClamshellState"/{gsub(/[ ;]/,"",$2); print $2; exit}')
  if [ "$state" = "Yes" ]; then
    if [ "$closed" != "1" ]; then
      /usr/bin/pmset displaysleepnow >/dev/null 2>&1 || true
      closed=1
    fi
  else
    closed=0
  fi
  sd=$(/usr/bin/pmset -g 2>/dev/null | awk '/SleepDisabled/{print $2; exit}')
  if [ "$sd" = "0" ]; then
    rm -f "$PIDFILE"
    exit 0
  fi
  sleep 2
done
