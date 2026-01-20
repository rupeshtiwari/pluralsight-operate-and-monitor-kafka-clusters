#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------
# Module 3 • Demo 2 — Correlate Logs with Metrics
# ---------------------------------------------

export COMPOSE_PROJECT_NAME=demo-2-m3-correlate-logs-metrics
export COMPOSE_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/docker-compose.yml"

# Avoid accidental overrides (common cause of weird DNS / "no such host")
unset DOCKER_HOST DOCKER_CONTEXT COMPOSE_PROFILES

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

session="m3-demo2"

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

# If healthchecks exist, wait. If not, we still give Kafka a short warmup.
echo "Waiting for brokers to be ready..."
ready="yes"
for b in broker1 broker2 broker3; do
  status="$(docker inspect -f '{{.State.Health.Status}}' "$b" 2>/dev/null || true)"
  if [[ -n "$status" ]]; then
    printf -- "- %s: " "$b"
    ok="no"
    for _ in $(seq 1 45); do
      status="$(docker inspect -f '{{.State.Health.Status}}' "$b" 2>/dev/null || true)"
      if [[ "$status" == "healthy" ]]; then ok="yes"; break; fi
      sleep 1
    done
    if [[ "$ok" == "yes" ]]; then
      echo "[OK] healthy"
    else
      echo "[ERR] not healthy"
      ready="no"
    fi
  fi
done

if [[ "$ready" != "yes" ]]; then
  echo "One or more brokers didn't report healthy. Try: ./stop-demo.sh then re-run." >&2
  exit 1
fi

# Warmup (needed even when no healthchecks are present)
sleep 2

echo
echo "URLs:"
echo "  Grafana:    http://localhost:3000  (admin/admin)"
echo "  Prometheus: http://localhost:9090/targets"
echo

# Fresh tmux
(tmux has-session -t "$session" 2>/dev/null) && tmux kill-session -t "$session" || true

# Clean shell (kills your zsh theme noise)
run_clean() {
  # PS1 shows "$ " (escaped so it is not expanded by outer script)
  printf "%s" "cd '$ROOT_DIR'; clear; env PS1='\\$ ' bash --noprofile --norc"
}

# 3 panes: top (T1), bottom-left (T2), bottom-right (T3)
tmux new-session -d -s "$session" -n "demo" -c "$ROOT_DIR" "$(run_clean)"
tmux split-window -v -t "$session":0 -c "$ROOT_DIR" "$(run_clean)"
tmux split-window -h -t "$session":0.1 -c "$ROOT_DIR" "$(run_clean)"

# Show pane titles as top border bar
# (This is what gives you the colored header strip)
tmux set-option -t "$session":0 -w pane-border-status top
tmux set-option -t "$session":0 -w pane-border-format "#{pane_title}"

# Borders always white (shared cross stays white)
tmux set-option -t "$session":0 -w pane-border-style "fg=white"
tmux set-option -t "$session":0 -w pane-active-border-style "fg=white"

# Titles (colored)
t1_title="#[bg=colour27,fg=white,bold]   T1 - Control + Lag   #[default]"
t2_title="#[bg=colour160,fg=white,bold]  T2 - Broker2 Logs (High-Signal)  #[default]"
t3_title="#[bg=colour214,fg=black,bold]  T3 - Producer Load  #[default]"

# Apply titles
# Pane index after splits: 0.0 = top, 0.1 = bottom-left, 0.2 = bottom-right
tmux select-pane -t "$session":0.0 -T "$t1_title"
tmux select-pane -t "$session":0.1 -T "$t2_title"
tmux select-pane -t "$session":0.2 -T "$t3_title"

# Run hints in panes (keep these short)
tmux send-keys -t "$session":0.0 "clear; printf '\nRun order (T1):\n  1) ./scripts/01-create-topic.sh\n  2) ./scripts/03-start-consumer.sh &\n  3) ./scripts/10-watch-lag.sh\n  4) ./scripts/09-restart-broker2.sh  (incident)\n\nPrimary teaching happens in Grafana (timestamps).\n\n'" Enter

tmux send-keys -t "$session":0.1 "clear; printf '\nRun BEFORE incident:\n  ./scripts/06-watch-broker2-events.sh\n\nTip: when p99 jumps in Grafana, read 1-2 lines with the same timestamp.\n\n'" Enter

tmux send-keys -t "$session":0.2 "clear; printf '\nRun and leave it running:\n  ./scripts/02-start-load.sh\n\nDefaults: ~4 minutes, ~25k rps target\n\n'" Enter

# Focus T1
(tmux select-pane -t "$session":0.0) >/dev/null

# Attach or switch depending on where we are
if [[ -n "${TMUX:-}" ]]; then
  tmux switch-client -t "$session"
else
  tmux attach-session -t "$session"
fi
