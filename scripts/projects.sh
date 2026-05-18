#!/usr/bin/env bash
# tmux project picker — fuzzy-search shortcuts from config.json in a top popup,
# then open (or focus) the matching named window.
# Colours are pulled from the tmux palette (@primary / @secondary):
#   normal item  = fg secondary, no background
#   selected line= fg primary on secondary background
# Bound to `prefix + t` (see tmux.conf "Templates").
set -euo pipefail

export PATH="/opt/homebrew/bin:$PATH"   # popup shell may lack brew path
CONFIG="${HOME}/.config/tmux/config.json"

[ -f "$CONFIG" ] || { tmux display-message "config.json not found: $CONFIG"; exit 0; }

primary=$(tmux show -gv @primary 2>/dev/null || echo '#cfcfcf')
secondary=$(tmux show -gv @secondary 2>/dev/null || echo '#5c5b5b')

sel=$(jq -r '.[].label' "$CONFIG" | fzf \
  --layout=reverse --height=100% --border=none --no-multi --cycle \
  --prompt="" --pointer="" --marker="" --scrollbar="" \
  --info=inline --info-command='printf ""' --separator="─" \
  --color="fg:${secondary},bg:-1,gutter:-1,fg+:${primary},bg+:${secondary},hl:${primary},hl+:${primary},query:${primary},info:${secondary},separator:${secondary},spinner:${secondary}") \
  || exit 0
[ -z "$sel" ] && exit 0

entry=$(jq -c --arg l "$sel" '.[] | select(.label == $l)' "$CONFIG")
[ -z "$entry" ] && { tmux display-message "no entry for: $sel"; exit 0; }

path=$(jq -r '.path' <<<"$entry")
venv=$(jq -r '.source_venv // false' <<<"$entry")
path="${path/#\~/$HOME}"          # expand leading ~

[ -d "$path" ] || { tmux display-message "path not found: $path"; exit 0; }

idx=$(tmux list-windows -F '#{window_index} #{window_name}' \
  | awk -v n="$sel" '$2 == n { print $1; exit }')

if [ -n "$idx" ]; then
  tmux select-window -t ":$idx"
else
  tmux new-window -n "$sel" -c "$path"
  if [ "$venv" = "true" ]; then
    tmux send-keys -t ":$sel" 'source .venv/bin/activate' Enter
  fi
fi
