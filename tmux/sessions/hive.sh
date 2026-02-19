#!/usr/bin/env bash
set -euo pipefail

SESSION="hive"

if tmux has-session -t "$SESSION" 2>/dev/null; then
  if [ -n "${TMUX:-}" ]; then
    tmux switch-client -t "$SESSION"
  else
    tmux attach-session -t "$SESSION"
  fi
  exit 0
fi

tmux new-session -d -s "hive" -n "frontend/backend" -c "/home/ni3rav/code/hive/frontend"
tmux split-window -t "hive":0 -c "/home/ni3rav/code/hive/backend"
tmux select-layout -t "hive":0 "8be0,188x46,0,0{93x46,0,0,1,94x46,94,0,2}"
tmux select-pane -t "hive":0.1
tmux new-window -t "hive" -n "function/docs/db" -c "/home/ni3rav/code/hive/functions"
tmux split-window -t "hive":1 -c "/home/ni3rav/code/hive/docs"
tmux split-window -t "hive":1 -c "/home/ni3rav/code/hive/backend"
tmux select-layout -t "hive":1 "8cea,188x46,0,0{80x46,0,0,3,107x46,81,0[107x22,81,0,4,107x23,81,23,5]}"
tmux select-pane -t "hive":1.1

tmux select-window -t "hive":1
if [ -n "${TMUX:-}" ]; then
  tmux switch-client -t "$SESSION"
else
  tmux attach-session -t "$SESSION"
fi
