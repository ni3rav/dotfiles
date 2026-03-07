#!/usr/bin/env bash
set -euo pipefail

SESSION="0"

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

tmux new-session -d -s "0" -n "zsh" -c "/home/ni3rav/code/shepherd"
tmux select-layout -t "0":0 "b11d,209x50,0,0,0"
tmux select-pane -t "0":0.0
tmux new-window -t "0" -n "bun" -c "/home/ni3rav/code/shepherd"
tmux split-window -t "0":1 -c "/home/ni3rav/code/shepherd/apps/api"
tmux split-window -t "0":1 -c "/home/ni3rav/code/shepherd"
tmux split-window -t "0":1 -c "/home/ni3rav/code/shepherd"
tmux split-window -t "0":1 -c "/home/ni3rav/code/shepherd/apps/worker"
tmux select-layout -t "0":1 "8f33,209x50,0,0{104x50,0,0[104x25,0,0,1,104x24,0,26,4],104x50,105,0[104x25,105,0{63x25,105,0,2,40x25,169,0,5},104x24,105,26,3]}"
tmux select-pane -t "0":1.4

tmux select-window -t "0":1
if [ -n "${TMUX:-}" ]; then
  tmux switch-client -t "$SESSION"
else
  tmux attach-session -t "$SESSION"
fi
