#!/bin/sh
# Shade the status bar so it stands apart from the panes.
# catppuccin-tmux bakes its base colour into every status segment, so after the
# plugin has run, swap base for a darker shade in each status option.
from="#1e1e2e"          # Catppuccin Mocha base (pane background)
to="${1:-#11111b}"      # Catppuccin Mocha crust
for o in status-bg status-left status-right window-status-style window-status-activity-style \
         window-status-format window-status-current-format; do
  v=$(tmux show -gv "$o" 2>/dev/null) || continue
  tmux set -g "$o" "$(printf '%s' "$v" | sed "s/$from/$to/g")"
done
