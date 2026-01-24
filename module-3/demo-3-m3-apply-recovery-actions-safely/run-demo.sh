#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

export COMPOSE_FILE="$ROOT_DIR/docker-compose.yml"
export COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-m3_demo3}"

unset DOCKER_HOST DOCKER_CONTEXT COMPOSE_PROFILES

session="m3-demo3"
NETWORK="ps-kafka-m2-demo2-net"

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

title "🧹 Cleanup conflicting containers (fixed container_name)"
for c in zookeeper broker1 broker2 broker3 kafka-exporter prometheus grafana; do
  docker rm -f "$c" >/dev/null 2>&1 || true
done

title "🌐 Ensure shared Docker network exists"
if docker network inspect "$NETWORK" >/dev/null 2>&1; then
  echo "Network OK: $NETWORK"
else
  echo "Creating network: $NETWORK"
  docker network create "$NETWORK" >/dev/null
fi

title "🚀 Start Kafka Demo Environment"
echo "📦 Bringing up Docker Compose services..."
docker compose up -d --force-recreate --remove-orphans

title "⏳ Wait for Kafka (broker1) to be reachable"
for i in $(seq 1 90); do
  status="$(docker inspect -f '{{.State.Status}}' broker1 2>/dev/null || echo missing)"
  if [[ "$status" != "running" ]]; then
    printf "[%d/90] broker1 status=%s (waiting...)\n" "$i" "$status"
    sleep 1
    continue
  fi

  if docker exec broker1 bash -lc "kafka-broker-api-versions --bootstrap-server broker1:9092 >/dev/null 2>&1"; then
    echo "✅ Kafka is reachable."
    break
  fi

  printf "[%d/90] Kafka not ready yet...\n" "$i"
  sleep 1

  if [[ "$i" -eq 90 ]]; then
    echo "❌ Kafka still not reachable. Check logs:"
    echo "   docker logs --tail=120 broker1"
    exit 1
  fi
done

echo
echo "🌐 URLs:"
echo "  📈 Grafana:    http://localhost:3000  (admin/admin)"
echo "  📊 Prometheus: http://localhost:9090/targets"
echo

tmux kill-session -t "$session" 2>/dev/null || true

run_clean() { printf "%s" "cd '$ROOT_DIR'; export PS1='\$ '; exec bash --noprofile --norc"; }

tmux new-session -d -s "$session" -n "demo" -c "$ROOT_DIR" "$(run_clean)"
tmux split-window -v -t "$session":0 -c "$ROOT_DIR" "$(run_clean)"
tmux split-window -h -t "$session":0.1 -c "$ROOT_DIR" "$(run_clean)"

tmux set-option -t "$session":0 -w pane-border-status top
tmux set-option -t "$session":0 -w pane-border-format "#{pane_title}"
tmux set-option -t "$session":0 -w pane-border-style "fg=white"
tmux set-option -t "$session":0 -w pane-active-border-style "fg=white"

t1_title="#[bg=colour160,fg=white,bold]  T1 - Broker2 Logs (High-Signal)  #[default]"
t2_title="#[bg=colour27,fg=white,bold]   T2 - Control + Lag   #[default]"
t3_title="#[bg=colour214,fg=black,bold]  T3 - Producer Load  #[default]"

tmux select-pane -t "$session":0.0 -T "$t1_title"
tmux select-pane -t "$session":0.1 -T "$t2_title"
tmux select-pane -t "$session":0.2 -T "$t3_title"

tmux send-keys -t "$session":0.0 "clear; cat <<'TXT'

T1: Broker2 High-Signal Logs
--------------------------------
Run BEFORE incident:
  ./scripts/06-watch-broker2-events.sh

(or raw logs):
  ./scripts/08-tail-broker2-logs.sh

Tip: when lag/p99 spikes in Grafana, correlate timestamps with these lines.
TXT" C-m

tmux send-keys -t "$session":0.1 "clear; cat <<'TXT'

T2: Control + Lag
------------------
Run order:
  1) ./scripts/01-create-topic.sh
  2) ./scripts/03-start-consumer.sh
  3) ./scripts/10-watch-lag.sh        (leave running)

Incident:
  4) ./scripts/09-restart-broker2.sh

Verify + Recover:
  5) ./scripts/12-verify-isr.sh
  6) (Ctrl+C watch-lag) ./scripts/11-reset-offsets-to-latest.sh
  7) ./scripts/04-check-lag.sh
TXT" C-m

tmux send-keys -t "$session":0.2 "clear; cat <<'TXT'

T3: Producer Load
------------------
Run and leave it running:
  ./scripts/02-start-load.sh

Defaults: ~150s, ~25k msg/s target
TXT" C-m

tmux select-pane -t "$session":0.1 >/dev/null

if [[ -n "${TMUX:-}" ]]; then
  tmux switch-client -t "$session"
else
  tmux attach-session -t "$session"
fi
