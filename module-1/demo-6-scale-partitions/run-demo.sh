#!/usr/bin/env bash

session="kafka-demo-6"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
start_dir="$script_dir"

if tmux has-session -t "$session" 2>/dev/null; then
  tmux kill-session -t "$session"
fi

t1_title="#[bg=colour27,fg=white,bold]   T1 - ISR Monitor   #[default]"
t5_title="#[bg=colour33,fg=white,bold]   T5 - Leader Monitor   #[default]"
t2_title="#[bg=colour34,fg=black,bold]   T2 - Consumer   #[default]"
t3_title="#[bg=colour214,fg=black,bold]   T3 - Lag Monitor   #[default]"
t4_title="#[bg=colour200,fg=black,bold]   T4 - Producer Load   #[default]"

run_clean() {
  echo "cd '$start_dir'; clear; zsh"
}

# pane0 full screen
tmux new-session -d -s "$session" -n "kafka" "$(run_clean)"

# pane1 bottom full width
tmux split-window -v -t "$session":0.0 "$(run_clean)"

# split bottom into left (future T2) and right (future T4)
tmux select-pane -t "$session":0.1
tmux split-window -h -t "$session":0.1 "$(run_clean)"

# now create bottom row for T3 by splitting pane1 vertically and moving pane
# easier: split pane1 again, then swap so pane2 becomes bottom full width
tmux select-pane -t "$session":0.1
tmux split-window -v -t "$session":0.1 "$(run_clean)"
# panes now: 0 top, 1 mid-left, 3 mid-right, 2 bottom
# that matches your old layout

# now split top (pane0) horizontally to create T1 and T5
tmux select-pane -t "$session":0.0
tmux split-window -h -t "$session":0.0 "$(run_clean)"
# panes: 0 top-left, 4 top-right, 1 mid-left, 3 mid-right, 2 bottom

# titles
tmux select-pane -t "$session":0.0 -T "$t1_title"
tmux select-pane -t "$session":0.4 -T "$t5_title"
tmux select-pane -t "$session":0.1 -T "$t2_title"
tmux select-pane -t "$session":0.3 -T "$t4_title"
tmux select-pane -t "$session":0.2 -T "$t3_title"

tmux select-pane -t "$session":0.0
tmux attach-session -t "$session"
