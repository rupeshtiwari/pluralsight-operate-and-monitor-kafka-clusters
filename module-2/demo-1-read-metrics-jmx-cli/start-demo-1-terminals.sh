#!/usr/bin/env bash

session="kafka-demo"

# Directory where this script lives
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# All panes start inside: current demo directory
start_dir="$(cd "$script_dir" && pwd)"

# Always start fresh
if tmux has-session -t "$session" 2>/dev/null; then
  tmux kill-session -t "$session"
fi

# --------------------------------------------------------------------
# COLOR HEADING HELPERS
# --------------------------------------------------------------------
t1_title="#[bg=colour27,fg=white,bold]   Broker Metrics (JMX)   #[default]"
t2_title="#[bg=colour34,fg=black,bold]   Consumer Lag (CLI)   #[default]"
t3_title="#[bg=colour214,fg=black,bold]   Producer Load   #[default]"

# helper: start CLI pane in demo directory, then zsh
run_cli() {
  echo "cd '$start_dir'; zsh"
}

# helper: start broker pane
run_broker() {
  echo "docker exec -it broker1 bash"
}

# --------------------------------------------------------------------
# CREATE LAYOUT (3 vertical panes)
# --------------------------------------------------------------------

# Pane 0: Broker Metrics (JMX) - top
tmux new-session -d -s "$session" -n "kafka" "$(run_broker)"

# Pane 1: Consumer Lag (CLI) - middle
tmux split-window -v -t "$session":0.0 "$(run_broker)"

# Pane 2: Producer Load - bottom
tmux select-pane -t "$session":0.1
tmux split-window -v -t "$session":0.1 "$(run_broker)"

# --------------------------------------------------------------------
# APPLY TITLES WITH BACKGROUND SHADING
# --------------------------------------------------------------------
tmux select-pane -t "$session":0.0 -T "$t1_title"  # top
tmux select-pane -t "$session":0.1 -T "$t2_title"  # middle
tmux select-pane -t "$session":0.2 -T "$t3_title"  # bottom

# Focus T1 initially
tmux select-pane -t "$session":0.0

# Attach
tmux attach-session -t "$session"
