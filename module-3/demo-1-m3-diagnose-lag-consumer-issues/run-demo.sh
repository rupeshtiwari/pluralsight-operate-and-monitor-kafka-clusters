#!/usr/bin/env bash
set -euo pipefail

export COMPOSE_PROJECT_NAME=demo-1-m3-diagnose-lag-consumer-issues
export COMPOSE_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/docker-compose.yml"

# Avoid accidental overrides (common cause of weird DNS / "no such host")
unset DOCKER_HOST DOCKER_CONTEXT COMPOSE_PROFILES

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

session="m3-demo1"

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1"; exit 1; }; }
need docker
need tmux

hr() { printf '%s\n' "────────────────────────────────────────────────────────────────────────────────"; }
title() { printf '\n%s\n' "$1"; hr; }

if [[ "${1:-}" == "--down" ]]; then
  tmux kill-session -t "$session" 2>/dev/null || true
  docker compose down -v --remove-orphans || true
  exit 0
fi

title "Start Kafka Demo Environment"
echo "Bringing up Docker Compose services"
docker compose up -d --force-recreate --remove-orphans

echo "Waiting for broker healthchecks"
for b in broker1 broker2 broker3; do
  printf -- "- %s: " "$b"
  ok="no"
  for _ in $(seq 1 45); do
    status="$(docker inspect -f '{{.State.Health.Status}}' "$b" 2>/dev/null || true)"
    if [[ "$status" == "healthy" ]]; then
      ok="yes"
      break
    fi
    sleep 1
  done
  if [[ "$ok" == "yes" ]]; then
    echo "[OK] healthy"
  else
    echo "[ERR] not healthy"
    echo "Tip: run ./stop-demo.sh and try again"
    exit 1
  fi
done
echo "[OK] Kafka brokers are ready"

# Ensure topic exists (your existing script)
"$ROOT_DIR/scripts/02-ensure-topic-ready.sh"

echo
echo "tmux panes:"
echo "  T1: Lag view"
echo "  T2: Consumer state"
echo "  T3: Start load"
echo "  T4: Start consumer"
echo

# Fresh tmux
tmux has-session -t "$session" 2>/dev/null && tmux kill-session -t "$session" || true

# Titles (static, colored)
t1_title="#[bg=colour27,fg=white,bold]   T1 - Lag View               #[default]"
t2_title="#[bg=colour198,fg=white,bold]  T2 - Consumer State         #[default]"
t3_title="#[bg=colour46,fg=black,bold]   T3 - Producer Load          #[default]"
t4_title="#[bg=colour226,fg=black,bold]  T4 - Start Consumer         #[default]"

# Clean shell without your zsh prompt theme noise
run_clean() {
  # PS1 shows "$ " (escaped so it is not expanded by the outer script)
  printf "%s" "cd '$ROOT_DIR'; clear; env PS1='\$ ' bash --noprofile --norc"
}

# Create session + 2x2 panes (deterministic)
tmux new-session -d -s "$session" -n "demo" -c "$ROOT_DIR" "$(run_clean)"
tmux split-window -h -t "$session":0 -c "$ROOT_DIR" "$(run_clean)"
tmux split-window -v -t "$session":0.0 -c "$ROOT_DIR" "$(run_clean)"
tmux split-window -v -t "$session":0.1 -c "$ROOT_DIR" "$(run_clean)"
tmux select-layout -t "$session":0 tiled

# Window settings: show pane titles on top line
tmux set-option -t "$session":0 -w pane-border-status top
tmux set-option -t "$session":0 -w pane-border-format "#{pane_title}"

# Borders always white (shared cross stays white)
tmux set-option -t "$session":0 -w pane-border-style "fg=white"
tmux set-option -t "$session":0 -w pane-active-border-style "fg=white"

# Apply titles to panes (these render because pane-border-format uses #{pane_title})
tmux select-pane -t "$session":0.0 -T "$t1_title"
tmux select-pane -t "$session":0.1 -T "$t2_title"
tmux select-pane -t "$session":0.2 -T "$t3_title"
tmux select-pane -t "$session":0.3 -T "$t4_title"

# Optional run hints inside panes
tmux send-keys -t "$session":0.0 "clear; printf '\nRun: ./scripts/05-watch-lag.sh\n\n'" Enter
tmux send-keys -t "$session":0.1 "clear; printf '\nRun: ./scripts/06-show-consumer-state.sh\n\n'" Enter
tmux send-keys -t "$session":0.2 "clear; printf '\nRun: ./scripts/03-start-load.sh\n\n'" Enter
tmux send-keys -t "$session":0.3 "clear; printf '\nRun: ./scripts/04-start-consumer.sh\n\n'" Enter

tmux select-pane -t "$session":0.0

# Attach or switch depending on where we are
if [[ -n "${TMUX:-}" ]]; then
  tmux switch-client -t "$session"
else
  tmux attach-session -t "$session"
fi
