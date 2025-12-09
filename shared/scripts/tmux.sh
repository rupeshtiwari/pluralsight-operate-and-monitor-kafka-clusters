#!/usr/bin/env bash

session="kafka-demo"

# Directory where this script lives
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# All panes should start in: code/demo-2-detect-lag
start_dir="$(cd "$script_dir/../../demo-2-detect-lag" && pwd)"

# Always start fresh: kill old session if it exists
if tmux has-session -t "$session" 2>/dev/null; then
  tmux kill-session -t "$session"
fi

# --- Create new session and panes ---

# T1 — Top Left: Cluster Control (blue title)
tmux new-session -d -s "$session" -n "kafka" "cd '$start_dir'; zsh"
tmux select-pane -t "$session":0.0 -T '#[fg=colour39,bold] Cluster Control '

# T2 — Top Right: ISR Monitor (orange title)
tmux split-window -h -t "$session":0.0 "cd '$start_dir'; zsh"
tmux select-pane -t "$session":0.1 -T '#[fg=colour208,bold] ISR Monitor '

# T3 — Bottom Left: Broker 1 Shell (green title)
tmux split-window -v -t "$session":0.0 "cd '$start_dir'; zsh"
tmux select-pane -t "$session":0.2 -T '#[fg=colour82,bold] Broker 1 Shell '

# T4 — Bottom Right: Lag Monitor (magenta title)
tmux split-window -v -t "$session":0.1 "cd '$start_dir'; zsh"
tmux select-pane -t "$session":0.3 -T '#[fg=colour201,bold] Lag Monitor '

# Arrange panes into a 2×2 grid
tmux select-layout -t "$session":0 tiled

# Re-apply titles in case layout reshuffled
tmux select-pane -t "$session":0.0 -T '#[fg=colour39,bold] Cluster Control '
tmux select-pane -t "$session":0.1 -T '#[fg=colour208,bold] ISR Monitor '
tmux select-pane -t "$session":0.2 -T '#[fg=colour82,bold] Broker 1 Shell '
tmux select-pane -t "$session":0.3 -T '#[fg=colour201,bold] Lag Monitor '

# Focus Cluster Control by default
tmux select-pane -t "$session":0.0

# Attach to the session
tmux attach-session -t "$session"
