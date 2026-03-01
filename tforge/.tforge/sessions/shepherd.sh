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

tmux new-session -d -s "0" -n "web/api/compose" -c "/home/ni3rav/code/shepherd/apps/web"
tmux split-window -t "0":0 -c "/home/ni3rav/code/shepherd"
tmux split-window -t "0":0 -c "/home/ni3rav/code/shepherd/apps/api"
tmux select-layout -t "0":0 "fbdf,209x50,0,0{104x50,0,0[104x25,0,0,0,104x24,0,26,4],104x50,105,0,3}"
tmux select-pane -t "0":0.2
tmux new-window -t "0" -n "packages" -c "/home/ni3rav/code/shepherd/packages/logger"
tmux split-window -t "0":1 -c "/home/ni3rav/code/shepherd/packages/whistle"
tmux split-window -t "0":1 -c "/home/ni3rav/code/shepherd/packages/crook"
tmux split-window -t "0":1 -c "/home/ni3rav/code/shepherd/packages/types"
tmux select-layout -t "0":1 "d35b,209x50,0,0{104x50,0,0[104x25,0,0,1,104x24,0,26,8],104x50,105,0[104x25,105,0,5,104x24,105,26,7]}"
tmux select-pane -t "0":1.0
tmux new-window -t "0" -n "git" -c "/home/ni3rav/code/shepherd"
tmux select-layout -t "0":2 "b11f,209x50,0,0,2"
tmux select-pane -t "0":2.0

tmux select-window -t "0":0
if [ -n "${TMUX:-}" ]; then
  tmux switch-client -t "$SESSION"
else
  tmux attach-session -t "$SESSION"
fi
