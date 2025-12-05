#!/bin/bash

BROWSER="zen-browser"
BROWSER_CLASS="zen"
SLEEP_TIME=0.5
ACTIVE_ONLY=false
BROWSER_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    --sleep=*)
      SLEEP_TIME="${1#--sleep=}"
      shift
      ;;
    --sleep)
      SLEEP_TIME="$2"
      shift 2
      ;;
    --active-only)
      ACTIVE_ONLY=true
      shift
      ;;
    *)
      BROWSER_ARGS+=("$1")
      shift
      ;;
  esac
done

if [[ "$ACTIVE_ONLY" = true ]]; then
  active_class=$(hyprctl activewindow -j 2>/dev/null | jq -r .class)
  if [[ "$active_class" != "$BROWSER_CLASS" ]]; then
    exit 0
  fi
fi

"$BROWSER" "${BROWSER_ARGS[@]}" &
echo "Started $BROWSER with args: ${BROWSER_ARGS[*]}"
sleep "$SLEEP_TIME"
echo "Slept for $SLEEP_TIME seconds"
browser_address=$(hyprctl clients -j 2>/dev/null | jq -r ".[] | select(.class == \"${BROWSER_CLASS}\").address" | tail -1)
echo "Retrieved browser address: $browser_address"
if [ -n "$browser_address" ]; then
  hyprctl dispatch settiled address:"$browser_address"
  echo "Set browser window to tiled mode"
fi
