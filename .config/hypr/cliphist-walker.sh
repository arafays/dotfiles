#!/usr/bin/env bash
# cliphist-walker.sh - show cliphist using walker dmenu and copy selected entry

set -euo pipefail

# Use cliphist list to get entries, present with walker dmenu, decode selection and copy
selection=$(cliphist list | walker --dmenu --theme dmenu_250 -p "Clipboard…") || exit 0

# If selection is empty, exit quietly
if [[ -z "$selection" ]]; then
  exit 0
fi

# cliphist decode expects the index; walker returns the line text, so find its index
index=$(cliphist list | grep -nxF "$selection" | cut -d: -f1 | head -n1)

if [[ -z "$index" ]]; then
  # Fallback: try decoding by passing the exact text (some cliphist versions accept it)
  printf "%s" "$selection" | wl-copy
  exit 0
fi

cliphist decode "$index" | wl-copy
