#!/bin/sh
# tmux-resurrect post-save hook: keep only the newest saves (resurrect itself only prunes by age).
# Pane contents live in one file that every save overwrites, so only the layouts pile up.
keep=10
dir="$HOME/.tmux/resurrect"
[ -d "$dir" ] || dir="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect"
[ -d "$dir" ] || exit 0

ls -1t "$dir"/tmux_resurrect_*.txt 2>/dev/null | tail -n +$((keep + 1)) | xargs -r rm -f
