#!/usr/bin/env bash

session="kafka-demo"

# Directory where this script lives
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# All panes start inside: code/demo-2-detect-lag
start_dir="$(cd "$script_dir/../../demo-2-detect-lag" && pwd)"

# Always start fresh
if tmux has-session -t "$session" 2>/dev/null; then
  tmux kill-session -t "$session"
fi

# --------------------------------------------------------------------
# COLOR HEADING HELPERS
# --------------------------------------------------------------------
t1_title="#[bg=colour27,fg=white,bold]   T1 – Cluster Control & ISR Watch   #[default]"
t2_title="#[bg=colour34,fg=black,bold]   T2 – Broker1 Shell   #[default]"
t3_title="#[bg=colour214,fg=black,bold]   T3 – Lag Monitor   #[default]"
t4_title="#[bg=colour200,fg=black,bold]   T4 – Producer Load   #[default]"

# helper: start pane in demo-2-detect-lag, clear, then zsh
run_clean() {
  echo "cd '$start_dir'; clean; zsh"
}

# --------------------------------------------------------------------
# CREATE LAYOUT (MATCHES YOUR DIAGRAM)
# --------------------------------------------------------------------

# Pane 0: T1 (top full-width)
tmux new-session -d -s "$session" -n "kafka" "$(run_clean)"

# Pane 1: temp bottom below T1
tmux split-window -v -t "$session":0.0 "$(run_clean)"

# Split the bottom area to create middle + bottom:
# Now: pane1 (middle), pane2 (bottom)
tmux select-pane -t "$session":0.1
tmux split-window -v -t "$session":0.1 "$(run_clean)"

# Split the middle pane horizontally for T2 (left) and T4 (right)
# After this:
#   pane0 = top (T1)
#   pane1 = middle-left  (T2)
#   pane3 = middle-right (T4)
#   pane2 = bottom       (T3)
tmux select-pane -t "$session":0.1
tmux split-window -h -t "$session":0.1 "$(run_clean)"

# --------------------------------------------------------------------
# APPLY TITLES WITH BACKGROUND SHADING
# --------------------------------------------------------------------
tmux select-pane -t "$session":0.0 -T "$t1_title"  # top
tmux select-pane -t "$session":0.1 -T "$t2_title"  # middle-left
tmux select-pane -t "$session":0.3 -T "$t4_title"  # middle-right
tmux select-pane -t "$session":0.2 -T "$t3_title"  # bottom

# Focus T1 initially
tmux select-pane -t "$session":0.0

# Attach
tmux attach-session -t "$session"
