#!/usr/bin/env bash
# Append the current window's path to config.json as a new shortcut.
#   $1 = label (from prefix+s command-prompt; Esc aborts before this runs)
# Errors out (no write) if an entry with the same *path* already exists.
set -euo pipefail

CONFIG="${HOME}/.config/tmux/config.json"
label="${1:-}"

[ -n "$label" ] || { tmux display-message "save aborted: empty label"; exit 0; }

path=$(tmux display-message -p '#{pane_current_path}')

# Store with a leading ~ for portability.
case "$path" in
  "$HOME")   store="~" ;;
  "$HOME"/*) store="~${path#"$HOME"}" ;;
  *)         store="$path" ;;
esac

[ -f "$CONFIG" ] || echo '[]' > "$CONFIG"

# Duplicate check: compare the new absolute path against every existing
# entry's path (expanding a leading ~).
dup=$(jq --arg ap "$path" --arg home "$HOME" '
  any(.[]; ((.path | if startswith("~") then $home + .[1:] else . end)) == $ap)
' "$CONFIG")

if [ "$dup" = "true" ]; then
  tmux display-message "already saved: $store"
  exit 0
fi

tmp=$(mktemp)
jq --arg l "$label" --arg p "$store" '. + [{label: $l, path: $p}]' "$CONFIG" > "$tmp" \
  && mv "$tmp" "$CONFIG"

tmux display-message "saved: $label → $store"
