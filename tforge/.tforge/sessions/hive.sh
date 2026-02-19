#!/usr/bin/env bash
set -euo pipefail

SESSION="hive"

if tmux has-session -t "$SESSION" 2>/dev/null; then
  WINDOWS=$(tmux list-windows -t "$SESSION" 2>/dev/null | wc -l | tr -d ' ')
  PANES=$(tmux list-panes -t "$SESSION" 2>/dev/null | wc -l | tr -d ' ')
  if [ "${WINDOWS:-0}" = "1" ] && [ "${PANES:-0}" = "1" ]; then
    tmux kill-session -t "$SESSION"
  else
    if [ -n "${TMUX:-}" ]; then
      tmux switch-client -t "$SESSION"
    else
      tmux attach-session -t "$SESSION"
    fi
    exit 0
  fi
fi

tmux new-session -d -s "hive" -n "frontend/backend" -c "/home/ni3rav/code/hive/frontend"
tmux split-window -t "hive":0 -c "/home/ni3rav/code/hive/backend"
tmux select-layout -t "hive":0 "15bc,188x46,0,0{94x46,0,0,0,93x46,95,0,1}"
tmux select-pane -t "hive":0.1
tmux new-window -t "hive" -n "docs/functions/db" -c "/home/ni3rav/code/hive/functions"
tmux split-window -t "hive":1 -c "/home/ni3rav/code/hive/docs"
tmux split-window -t "hive":1 -c "/home/ni3rav/code/hive/backend"
tmux select-layout -t "hive":1 "d5ae,188x46,0,0{94x46,0,0,2,93x46,95,0[93x23,95,0,3,93x22,95,24,4]}"
tmux select-pane -t "hive":1.0

tmux select-window -t "hive":0
if [ -n "${TMUX:-}" ]; then
  tmux switch-client -t "$SESSION"
else
  tmux attach-session -t "$SESSION"
fi
