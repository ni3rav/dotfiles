#!/usr/bin/env bash
set -euo pipefail

SESSION="shepherd"

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

tmux new-session -d -s "shepherd" -n "apps" -c "/home/ni3rav/code/shepherd/apps/web"
tmux split-window -t "shepherd":0 -c "/home/ni3rav/code/shepherd"
tmux split-window -t "shepherd":0 -c "/home/ni3rav/code/shepherd/apps/api"
tmux select-layout -t "shepherd":0 "ada3,188x46,0,0{94x46,0,0[94x18,0,0,5,94x27,0,19,6],93x46,95,0,7}"
tmux select-pane -t "shepherd":0.2
tmux new-window -t "shepherd" -n "packages" -c "/home/ni3rav/code/shepherd/packages"
tmux select-layout -t "shepherd":1 "d085,188x48,0,0,8"
tmux select-pane -t "shepherd":1.0
tmux new-window -t "shepherd" -n "git/root" -c "/home/ni3rav/code/shepherd"
tmux select-layout -t "shepherd":2 "d086,188x48,0,0,9"
tmux select-pane -t "shepherd":2.0

tmux select-window -t "shepherd":0
if [ -n "${TMUX:-}" ]; then
  tmux switch-client -t "$SESSION"
else
  tmux attach-session -t "$SESSION"
fi
