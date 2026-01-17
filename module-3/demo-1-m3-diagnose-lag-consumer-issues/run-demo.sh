#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

# Bring the environment to a known-good baseline
./scripts/01-prepare-state.sh
./scripts/02-ensure-topic-ready.sh

echo
echo "Next: tmux layout (recommended)"
echo "- Observe window: run ./scripts/05-watch-lag.sh in the large pane"
echo "- Actions window: run ./scripts/03-start-load.sh and ./scripts/04-start-consumer.sh"
echo

# If tmux is available, open an asymmetric layout to keep focus on the main signal
if command -v tmux >/dev/null 2>&1; then
  # Do not nest tmux sessions
  if [ -n "${TMUX-}" ]; then
    echo "Already inside tmux. Skipping tmux setup."
    exit 0
  fi

  SESSION="m3-demo1"

  # Clean previous session if it exists
  tmux has-session -t "$SESSION" 2>/dev/null && tmux kill-session -t "$SESSION"

  # Window 1: observe (big focus pane + two small proof panes)
  tmux new-session -d -s "$SESSION" -n observe -c "$(pwd)"
  tmux send-keys -t "$SESSION:observe.0" "clear; echo '[FOCUS] Run: ./scripts/05-watch-lag.sh'; echo 'Then: ./scripts/06-show-consumer-state.sh (when lag appears)';" C-m

  # Split right, make it narrow
  tmux split-window -h -t "$SESSION:observe.0" -c "$(pwd)"
  tmux send-keys -t "$SESSION:observe.1" "clear; echo '[PROOF] Run: ./scripts/07-watch-broker-load.sh';" C-m

  # Split bottom on the right for optional extra signal
  tmux split-window -v -t "$SESSION:observe.1" -c "$(pwd)"
  tmux send-keys -t "$SESSION:observe.2" "clear; echo '[OPTIONAL] Keep this pane idle, or use it for extra checks';" C-m

  # Select the big focus pane
  tmux select-pane -t "$SESSION:observe.0"

  # Window 2: actions (two panes for one-time commands)
  tmux new-window -t "$SESSION" -n actions -c "$(pwd)"
  tmux send-keys -t "$SESSION:actions.0" "clear; echo '[LOAD] Run: ./scripts/03-start-load.sh';" C-m
  tmux split-window -v -t "$SESSION:actions.0" -c "$(pwd)"
  tmux send-keys -t "$SESSION:actions.1" "clear; echo '[CONSUMER] Run: ./scripts/04-start-consumer.sh';" C-m

  # Start in observe window
  tmux select-window -t "$SESSION:observe"
  tmux attach -t "$SESSION"
else
  echo "tmux is not installed. Continue in separate terminals using the commands above."
fi
